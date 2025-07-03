# frozen_string_literal: true

require 'test_helper'

module Semdiff
  class AlgebraCompilerTest < TestCase
    def untyped_compilers
      []
    end

    def typed_compilers
      [AlgebraCompiler]
    end

    def test_simple_variable_commutativity
      assert_equivalent(
        <<~RUBY,
          # @param a [Numeric]
          # @param b [Numeric]
          def foo(a, b)
            a + b
            a * b
          end
        RUBY
        <<~RUBY
          # @param a [Numeric]
          # @param b [Numeric]
          def foo(a, b)
            b + a
            b * a
          end
        RUBY
      )
    end

    def test_literal_variable_commutativity
      assert_equivalent(
        <<~RUBY,
          # @param x [Numeric]
          def foo(x)
            1 + x
            2 * x
          end
        RUBY
        <<~RUBY
          # @param x [Numeric]
          def foo(x)
            x + 1
            x * 2
          end
        RUBY
      )
    end

    def test_literal_literal_commutativity
      assert_equivalent(
        <<~RUBY,
          def foo
            1 + 2
            3 * 4
          end
        RUBY
        <<~RUBY
          def foo
            2 + 1
            4 * 3
          end
        RUBY
      )
    end

    def test_different_variable_types_commutativity
      assert_equivalent(
        <<~RUBY,
          class Foo
            # @return [Integer]
            CONST = 1
            # @return [Numeric]
            attr_reader :value
            # @return [Numeric]
            @@cvar = 5
            class << self
              # @return [Numeric]
              attr_reader :ivar
            end
            # @param local [Numeric]
            def test(local)
              ivar + local
              @@cvar + local
              @value + CONST
              @value + ivar
            end
          end
        RUBY
        <<~RUBY
          class Foo
            # @return [Integer]
            CONST = 1
            # @return [Numeric]
            attr_reader :value
            # @return [Numeric]
            @@cvar = 5
            class << self
              # @return [Numeric]
              attr_reader :ivar
            end
            # @param local [Numeric]
            def test(local)
              local + ivar
              @@cvar + local
              @value + CONST
              ivar + @value
            end
          end
        RUBY
      )
    end

    def test_simple_associativity
      assert_equivalent(
        <<~RUBY,
          # @param lhs [Numeric]
          # @param rhs [Numeric]
          def foo(lhs, rhs)
            lhs + lhs + rhs
          end
        RUBY
        <<~RUBY
          # @param lhs [Numeric]
          # @param rhs [Numeric]
          def foo(lhs, rhs)
            lhs + rhs + lhs
          end
        RUBY
      )
    end

    def test_multiple_variable_associativity
      assert_equivalent(
        <<~RUBY,
          # @param a [Numeric]
          # @param b [Numeric]
          # @param c [Numeric]
          def foo(a, b, c)
            a + b + c
          end
        RUBY
        <<~RUBY
          # @param a [Numeric]
          # @param b [Numeric]
          # @param c [Numeric]
          def foo(a, b, c)
            c + b + a
          end
        RUBY
      )
    end

    def test_mixed_literal_variable_associativity
      assert_equivalent(
        <<~RUBY,
          # @param x [Numeric]
          # @param y [Numeric]
          def foo(x, y)
            1 + 2 + x + y
          end
        RUBY
        <<~RUBY
          # @param x [Numeric]
          # @param y [Numeric]
          def foo(x, y)
            2 + x + 1 + y
          end
        RUBY
      )
    end

    def test_multiplication_associativity
      assert_equivalent(
        <<~RUBY,
          # @param a [Numeric]
          # @param b [Numeric]
          # @param c [Numeric]
          def foo(a, b, c)
            a * b * c
            a * b * c
          end
        RUBY
        <<~RUBY
          # @param a [Numeric]
          # @param b [Numeric]
          # @param c [Numeric]
          def foo(a, b, c)
            c * a * b
            b * c * a
          end
        RUBY
      )
    end

    def test_parentheses_associativity
      assert_equivalent(
        <<~RUBY,
          # @param x [Numeric]
          # @param y [Numeric]
          # @param z [Numeric]
          def foo(x, y, z)
            x + y + z
            x + y + z
          end
        RUBY
        <<~RUBY
          # @param x [Numeric]
          # @param y [Numeric]
          # @param z [Numeric]
          def foo(x, y, z)
            (y + x) + z
            x + (z + y)
          end
        RUBY
      )
    end

    def test_complex_parentheses_associativity
      assert_equivalent(
        <<~RUBY,
          # @param a [Numeric]
          # @param b [Numeric]
          # @param c [Numeric]
          # @param d [Numeric]
          def foo(a, b, c, d)
            a + b + c + d
            a + b + c + d
            a + b + c + d
            a + b + c + d
          end
        RUBY
        <<~RUBY
          # @param a [Numeric]
          # @param b [Numeric]
          # @param c [Numeric]
          # @param d [Numeric]
          def foo(a, b, c, d)
            d + (c + (b + a))
            ((c + b) + a) + d
            ((c + b) + d) + a
            (d + c) + (b + a)
          end
        RUBY
      )
    end

    def test_non_numeric_no_change
      assert_equivalent(
        <<~RUBY,
          # @param s1 [String]
          # @param s2 [String]
          def foo(s1, s2)
            s2 + s1
          end
        RUBY
        <<~RUBY
          # @param s1 [String]
          # @param s2 [String]
          def foo(s1, s2)
            s2 + s1
          end
        RUBY
      )
    end

    def test_mixed_types_no_change
      assert_equivalent(
        <<~RUBY,
          # @param x [Numeric]
          # @param s [String]
          def foo(x, s)
            s + x.to_s
          end
        RUBY
        <<~RUBY
          # @param x [Numeric]
          # @param s [String]
          def foo(x, s)
            s + x.to_s
          end
        RUBY
      )
    end

    def test_non_commutative_operations_no_change
      assert_equivalent(
        <<~RUBY,
          # @param x [Numeric]
          # @param y [Numeric]
          def foo(x, y)
            y - x
            y / x
            y ** x
            y % x
          end
        RUBY
        <<~RUBY
          # @param x [Numeric]
          # @param y [Numeric]
          def foo(x, y)
            y - x
            y / x
            y ** x
            y % x
          end
        RUBY
      )
    end

    def test_addition_commutativity
      assert_equivalent(
        <<~RUBY,
          module Foo
            # @return [Integer]
            BAR = 1

            # @param x [Numeric]
            # @param y [Numeric]
            def swap_add(x, y)
              x + y
            end

            1 + 2
            1.5 + 2.0
            1 + 2.5
            2 + BAR
          end
        RUBY
        <<~RUBY
          module Foo
            # @return [Integer]
            BAR = 1

            # @param x [Numeric]
            # @param y [Numeric]
            def swap_add(x, y)
              y + x
            end

            2 + 1
            2.0 + 1.5
            2.5 + 1
            BAR + 2
          end
        RUBY
      )
    end

    def test_multiplication_commutativity
      assert_equivalent(
        <<~RUBY,
          module Foo
            # @return [Integer]
            BAZ = 5

            # @param a [Numeric]
            # @param b [Numeric]
            def swap_mul(a, b)
              a * b
            end

            3 * 4
            1.5 * 2.5
            2 * 3.5
            3 * BAZ
          end
        RUBY
        <<~RUBY
          module Foo
            # @return [Integer]
            BAZ = 5

            # @param a [Numeric]
            # @param b [Numeric]
            def swap_mul(a, b)
              b * a
            end

            4 * 3
            2.5 * 1.5
            3.5 * 2
            BAZ * 3
          end
        RUBY
      )
    end
  end
end
