# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'semdiff'
require 'minitest/autorun'

module Semdiff
  class TestCase < ::Minitest::Test
    # Load YARD builder files
    ::Typeguard::TypeModel::Builder.yard

    include IOUtils

    def untyped_compilers
      []
    end

    def typed_compilers
      []
    end

    def compilers(program_source)
      result = untyped_compilers.map(&:new)
      typed = typed_compilers
      unless typed.empty?
        with_types_desugared(program_source) do |_, node_types|
          result.concat(typed.map { |klass| klass.new(node_types) })
        end
      end
      result
    end

    # Equality checks with === operator (ignoring locations).
    # Parses an AST from the program source code instead of
    # building the nodes directly (with Prism::DSL) to avoid
    # source/location problems with `#inspect`.
    def assert_equivalent(canonical_source, program_source)
      expected_ast = Prism.parse(canonical_source).value
      actual_ast = Prism.parse(program_source).value
      compilers(program_source).each { |c| actual_ast = actual_ast.accept(c) }
      msg = <<~HEREDOC
        it should be canonical:
        #{program_source}
      HEREDOC
      assert_operator expected_ast, :===, actual_ast, msg
    end

    def sample_yard_sum
      <<~RUBY
        # @param lhs [Numeric] LHS
        # @param rhs [Numeric] RHS
        # @return [Numeric] sum of LHS and RHS
        def sum(lhs, rhs)
          lhs + rhs
        end
      RUBY
    end
  end
end
