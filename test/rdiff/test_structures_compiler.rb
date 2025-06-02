# frozen_string_literal: true

require 'test_helper'

module RDiff
  class StructuresCompilerTest < TestCase
    def untyped_compilers
      [StructuresCompiler]
    end

    def test_array_new_empty
      assert_equivalent '[]', 'Array.new'
    end

    def test_array_new_zero
      assert_equivalent '[]', 'Array.new(0)'
    end

    def test_array_new_with_size
      assert_equivalent 'Array.new(5)', 'Array.new(5)'
    end

    def test_array_new_with_size_and_default
      assert_equivalent 'Array.new(5, 0)', 'Array.new(5, 0)'
    end

    def test_array_new_with_block
      assert_equivalent 'Array.new { |i| i }', 'Array.new { |i| i }'
    end

    def test_array_new_with_variable
      assert_equivalent 'Array.new(n)', 'Array.new(n)'
    end

    def test_hash_new_empty
      assert_equivalent '{}', 'Hash.new'
    end

    def test_hash_new_with_default
      assert_equivalent 'Hash.new(0)', 'Hash.new(0)'
    end

    def test_hash_new_with_block
      assert_equivalent 'Hash.new { |h, k| h[k] = [] }', 'Hash.new { |h, k| h[k] = [] }'
    end

    def test_hash_bracket_empty
      assert_equivalent '{}', 'Hash[]'
    end

    def test_hash_bracket_with_args
      assert_equivalent 'Hash[a, b]', 'Hash[a, b]'
    end

    def test_hash_bracket_with_pairs
      assert_equivalent 'Hash[[[:a, 1], [:b, 2]]]', 'Hash[[[:a, 1], [:b, 2]]]'
    end

    def test_array_push_single
      assert_equivalent 'array << e', 'array.push(e)'
    end

    def test_array_push_literal
      assert_equivalent 'array << 42', 'array.push(42)'
    end

    def test_array_push_string
      assert_equivalent 'array << "hello"', 'array.push("hello")'
    end

    def test_array_push_multiple
      assert_equivalent 'array.push(a, b)', 'array.push(a, b)'
    end

    def test_array_push_no_args
      assert_equivalent 'array.push', 'array.push'
    end

    def test_array_push_with_call_operator
      assert_equivalent 'obj.array << e', 'obj.array.push(e)'
    end

    def test_array_push_chained
      assert_equivalent 'array << a << b', 'array.push(a).push(b)'
    end

    def test_string_concat_literal
      assert_equivalent '"a" << "b"', '"a".concat("b")'
    end

    def test_string_concat_single_quotes
      assert_equivalent "'a' << 'b'", "'a'.concat('b')"
    end

    def test_string_concat_variable
      assert_equivalent '"hello" << world', '"hello".concat(world)'
    end

    def test_string_concat_multiple_args
      assert_equivalent '"a".concat("b", "c")', '"a".concat("b", "c")'
    end

    def test_non_string_concat
      assert_equivalent 'array.concat(other)', 'array.concat(other)'
    end

    def test_variable_concat
      assert_equivalent 'str.concat("suffix")', 'str.concat("suffix")'
    end

    def test_hash_store_simple
      assert_equivalent 'hash[key] = value', 'hash.store(key, value)'
    end

    def test_hash_store_literals
      assert_equivalent 'hash[:key] = "value"', 'hash.store(:key, "value")'
    end

    def test_hash_store_numeric
      assert_equivalent 'hash[1] = 2', 'hash.store(1, 2)'
    end

    def test_hash_store_expressions
      assert_equivalent 'hash[a + b] = c * d', 'hash.store(a + b, c * d)'
    end

    def test_hash_store_wrong_args
      assert_equivalent 'hash.store(key)', 'hash.store(key)'
    end

    def test_hash_store_too_many_args
      assert_equivalent 'hash.store(key, value, extra)', 'hash.store(key, value, extra)'
    end

    def test_hash_store_with_call_operator
      assert_equivalent 'obj.hash[key] = value', 'obj.hash.store(key, value)'
    end

    def test_multiple_transformations
      assert_equivalent <<~RUBY.strip, <<~RUBY.strip
        array = []
        hash = {}
        array << 1
        hash[:key] = "value"
      RUBY
        array = Array.new
        hash = Hash.new
        array.push(1)
        hash.store(:key, "value")
      RUBY
    end

    def test_nested_transformations
      assert_equivalent '[] << {}', 'Array.new.push(Hash.new)'
    end

    def test_transformation_in_method_call
      assert_equivalent 'foo([], {})', 'foo(Array.new, Hash.new)'
    end

    def test_constant_not_array_or_hash
      assert_equivalent 'String.new', 'String.new'
    end

    def test_method_not_on_constant
      assert_equivalent 'variable.new', 'variable.new'
    end

    def test_method_not_push_concat_store
      assert_equivalent 'array.pop', 'array.pop'
    end

    def test_shovel_operator_unchanged
      assert_equivalent 'array << element', 'array << element'
    end

    def test_bracket_assign_unchanged
      assert_equivalent 'hash[key] = value', 'hash[key] = value'
    end
  end
end
