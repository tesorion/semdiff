# frozen_string_literal: true

require 'test_helper'

module RDiff
  class ConstantsCompilerTest < TestCase
    def untyped_compilers
      [ConstantsCompiler]
    end

    def test_parentheses
      assert_equivalent '2', '(2)'
    end

    def test_parentheses_nested
      assert_equivalent '2', '((2))'
    end

    def test_parentheses_binary_operator
      assert_equivalent '8', '(4 * 2)'
    end

    def test_parentheses_bitwise_operator
      assert_equivalent '256', '(1 << 8)'
    end

    def test_parentheses_multiple_statements
      assert_equivalent '(8; 4; 2)', '(8; 4; 2)'
    end

    def test_parentheses_multiple_statements_nested
      assert_equivalent '(2; 8; 16)', '((4 / 2); 4 * 2; ((4) << (2)))'
    end

    def test_parentheses_precedence
      assert_equivalent '24', '2 * (4 + 8)'
    end

    def test_operator_addition
      assert_equivalent '6', '4 + 2'
    end

    def test_operator_subtraction
      assert_equivalent '2', '4 - 2'
    end

    def test_operator_multiplication
      assert_equivalent '8', '4 * 2'
    end

    def test_operator_division
      assert_equivalent '2', '4 / 2'
    end

    def test_operator_modulo
      assert_equivalent '0', '4 % 2'
    end

    def test_operator_exponentiation
      assert_equivalent '16', '4 ** 2'
    end

    def test_operator_and
      assert_equivalent '0', '0b0100 & 0b0010'
    end

    def test_operator_or
      assert_equivalent '6', '0b0100 | 0b0010'
    end

    def test_operator_xor
      assert_equivalent '6', '0b0100 ^ 0b0010'
    end

    def test_operator_left_shift
      assert_equivalent '16', '0b0100 << 0b0010'
    end

    def test_operator_right_shift
      assert_equivalent '1', '0b0100 >> 0b0010'
    end

    def test_call_variables
      assert_equivalent 'a + b', 'a + b'
    end

    def test_call_variables_with_literals
      assert_equivalent '6 + a', '4 + 2 + a'
    end

    def test_call_variables_with_literals_precedence
      assert_equivalent '4 + 2 * a', '4 + 2 * a'
    end

    def test_call_floats
      assert_equivalent '2.0 + 4.0', '2.0 + 4.0'
    end

    def test_call_floats_with_integers
      assert_equivalent '2 + 4.0', '2 + 4.0'
    end

    def test_call_floats_with_integers_precedence
      assert_equivalent '2 + 4 * 8.0', '2 + 4 * 8.0'
    end

    def test_call_precedence
      assert_equivalent '20', '4 + 2 * 8'
    end

    def test_division_floor
      assert_equivalent '2', '7 / 3'
    end

    def test_right_associative_exponent
      assert_equivalent '256', '2 ** 2 ** 3'
    end

    def test_zero_division
      assert_equivalent '2 / 0', '2 / 0'
    end

    def test_negative_exponent
      assert_equivalent '2 ** -4', '2 ** -4'
    end
  end
end
