# frozen_string_literal: true

require 'test_helper'

module RDiff
  class IOUtilsTest < TestCase
    include Yard::TypeModel::Definitions

    def test_temp_file_exists
      f = temp_file('')
      assert_path_exists(f.path, 'it can create temporary files')
      File.unlink(f.path)
    end

    def test_temp_directory_exists
      dir = temp_dir
      assert_path_exists(dir, 'it can create temporary directories')
      FileUtils.remove_entry_secure(dir)
    end

    def test_yardoc_default_generation
      source = ''
      with_yardoc(source) do |files, dir|
        assert_equal(files.size, 1, 'it creates one file for one source')
        f = files.first
        assert_path_exists(f.path, 'it creates a valid file reference')
        assert_path_exists(dir, 'it creates a valid directory reference')
        assert(File.empty?(f.path), 'it creates an empty file')
        refute_empty(dir, 'it creates a non-empty directory')
      end
    end

    def test_prism_parse_lex
      source = <<~RUBY
        def sum(lhs, rhs)
          lhs + rhs
        end
      RUBY
      with_prism_parse_lex(source) do |_files, parse_lex_results|
        prism_result = parse_lex_results.first
        assert_kind_of(Prism::ParseLexResult, prism_result, 'it creates a ParseLexResult')
        program_node = prism_result.value.first
        definition_node = program_node.statements.body.find { |node| node.name == :sum }
        refute_nil(definition_node, 'it contains the sum node')
      end
    end

    def test_yardoc_and_prism
      source = sample_yard_sum
      with_yardoc_and_prism(source) do |files, dir, parse_lex_results|
        f = files.first
        prism_result = parse_lex_results.first
        refute(File.empty?(f.path), 'it creates a non-empty file')
        refute_empty(dir, 'it creates a non-empty directory')
        assert_kind_of(Prism::ParseLexResult, prism_result, 'it creates a ParseLexResult')
      end
    end

    def test_yard_types
      source = sample_yard_sum
      with_yard_types(source) do |_files, _dir, types|
        assert_kind_of(MethodDefinition, types.first, 'it creates a method definition for sum')
      end
    end

    def test_prism_and_yard_types
      source = sample_yard_sum
      with_prism_and_yard_types(source) do |files, dir, parse_lex_results, types|
        f = files.first
        prism_result = parse_lex_results.first
        refute(File.empty?(f.path), 'it creates a non-empty file')
        refute_empty(dir, 'it creates a non-empty directory')
        assert_kind_of(Prism::ParseLexResult, prism_result, 'it creates a ParseLexResult')
        assert_kind_of(MethodDefinition, types.first, 'it creates a method definition for sum')
      end
    end

    def test_full_prism_desugared
      source = <<~RUBY
        # @param a [Integer] some integer
        # @return [Integer] sugared increment of a
        def sugar(a)
          a += 1
        end
      RUBY
      with_full_prism_desugared(source) do |files, dir, program_nodes, types|
        f = files.first
        program_node = program_nodes.first
        write_node = program_node.statements.body.first.body.body.first
        refute(File.empty?(f.path), 'it creates a non-empty file')
        refute_empty(dir, 'it creates a non-empty directory')
        assert_kind_of(Prism::ProgramNode, program_node, 'it creates a ProgramNode')
        assert_kind_of(Prism::LocalVariableWriteNode, write_node, 'it desugars OperatorWrite into VariableWrite')
        assert_kind_of(MethodDefinition, types.first, 'it creates a method definition for sum')
      end
    end

    def test_with_prism
      source = <<~RUBY
        1 + 1
      RUBY
      with_prism_desugared(source) do |files, program_nodes|
        f = files.first
        program_node = program_nodes.first
        refute(File.empty?(f.path), 'it creates a non-empty file')
        assert_kind_of(Prism::ProgramNode, program_node, 'it creates a ProgramNode')
      end
    end

    def _test_rubocop_ast_no_bypass
      source = <<~RUBY
        def sample(value)
          value
        end
      RUBY
      with_rubocop_ast(source) do |_files, ast_results|
        ast = ast_results.first.ast
        assert_equal(ast.method_name, :sample, 'it contains the sample method definition node')
      end
    end

    def _test_rubocop_ast_with_bypass
      source = <<~RUBY
        def sample(value)
          value
        end
      RUBY
      with_temp_files(source) do |files|
        f = files.first
        prism_result = Prism.parse_lex_file(f.path)
        with_rubocop_ast_bypass([f, prism_result]) do |ast_results|
          ast = ast_results.first.ast
          assert_equal(ast.method_name, :sample, 'it contains the sample method definition node')
        end
      end
    end

    def _test_rubocop_ast_and_yard_types
      source = sample_yard_sum
      with_rubocop_ast_and_yard_types(source) do |files, dir, ast_results, types|
        f = files.first
        ast = ast_results.first.ast
        refute(File.empty?(f.path), 'it creates a non-empty file')
        refute_empty(dir, 'it creates a non-empty directory')
        assert_equal(ast.method_name, :sum, 'it contains the sum method definition node')
        assert_kind_of(MethodDefinition, types.first, 'it creates a method definition for sum')
      end
    end
  end
end
