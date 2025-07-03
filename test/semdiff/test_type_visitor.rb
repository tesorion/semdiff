# frozen_string_literal: true

require 'test_helper'

module Semdiff
  class TypeVisitorTest < ::Minitest::Test
    include IOUtils
    include NodeTypeFlags

    # @example
    #  ```ruby
    #  source = <<~RUBY
    #   module Foo
    #     # @return [Integer]
    #     BAR = 5
    #     BAR         # <-- read node with flags
    #     1 * BAR + 0 # <-- equal to a single read
    #   end
    #  RUBY
    #  flags = ONE | BASIC | INTEGER | NUMERIC # (NodeTypeFlags)
    #  msg = 'it associates module constants with type information'
    #  ```
    def assert_flags(program_source, flags, msg = nil)
      with_types_desugared(program_source) do |_, node_types|
        assert_equal flags.size, node_types.size, 'it has the expected amount of typed nodes'
        node_types.values.zip(flags).each { |exp, act| assert act.allbits?(exp), msg }
      end
    end

    def test_node_classes
      source = <<~RUBY
        class Foo
          # @return [Integer]
          @@class_var = 0
          @@class_var # 1
          # @return [Integer]
          CONST_VAR = 0
          CONST_VAR # 2
          # @return [Integer]
          attr_accessor :instance_var
          @instance_var # 3
          # @param local_var [Integer]
          def bar(local_var)
            local_var # 4
          end
          class << self
            # @return [Integer]
            attr_accessor :singleton_var
          end
          self.singleton_var # 5
          singleton_var # 6
        end
      RUBY
      assert_flags source, Array.new(6) { ONE | BASIC | INTEGER | NUMERIC }, 'it associates different nodes with types'
    end

    def test_types
      source = <<~RUBY
        module Foo
          # @return [Integer]
          AN_INTEGER = 0
          AN_INTEGER
          # @return [Float]
          A_FLOAT = 0.0
          A_FLOAT
          # @return [Boolean]
          A_BOOLEAN = true
          A_BOOLEAN
          # @return [String]
          A_STRING = ""
          A_STRING
          # @return [Array<Integer>]
          AN_ENUMERABLE = []
          AN_ENUMERABLE
          # @return [Integer, Float]
          A_NUMERIC_UNION = rand > 0.5 ? 0 : 0.0
          A_NUMERIC_UNION
        end
      RUBY

      assert_flags(source,
                   [
                     ONE | BASIC | INTEGER | NUMERIC,
                     ONE | BASIC | FLOAT | NUMERIC,
                     ONE | BASIC | BOOLEAN,
                     ONE | BASIC | STRING,
                     ONE | BASIC | ENUMERABLE,
                     NUMERIC
                   ], 'it associates YARD types with accurate flags')
    end

    def test_mixin_inheritance
      source = <<~RUBY
        module A
          # @return [Integer, Float]
          A_CONST = 0
          module B
            include A
            A_CONST # 1
          end
          module B::C
            include A
            A_CONST # 2
            module ::A
              A_CONST # 3
            end
          end
        end
        module A
          A_CONST # 4
          class B::C::D
            include A
            A_CONST # 5
            # @return [Integer, Float]
            @@baz = 0
          end
          class ::A::E < B::C::D
            A_CONST # 6
            # @return [Integer, Float]
            attr_accessor :bar
            class F < self
              A_CONST # 7
              @bar # 8
              @@baz # 9
            end
          end
        end
      RUBY
      assert_flags source, Array.new(9) { NUMERIC }, 'it supports mixins/inheritance of types'
    end
  end
end
