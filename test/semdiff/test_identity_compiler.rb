# frozen_string_literal: true

require 'test_helper'

module Semdiff
  class IdentityCompilerTest < TestCase
    def untyped_compilers
      []
    end

    def typed_compilers
      [IdentityCompiler]
    end

    def test_comments_ignored
      assert_equivalent 'def foo(bar) end', "# @param bar [Numeric]\ndef foo(bar) end"
    end

    def test_zero_addition
      assert_equivalent(
        <<~RUBY,
          class Foo
            attr_accessor :bar
            @bar = 1
            @@baz = 1
            QUX = 1.0
            class << self
              attr_accessor :quux
            end
            self.quux = Rational(1)
            def corge(grault)
              @bar
              @@baz
              QUX
              self.quux
              quux
              grault
            end
          end
        RUBY
        <<~RUBY
          class Foo
            # @return [Numeric]
            attr_accessor :bar
            @bar = 1
            # @return [Integer]
            @@baz = 1
            # @return [Float]
            QUX = 1.0
            class << self
              # @return [Rational]
              attr_accessor :quux
            end
            self.quux = Rational(1)
            # @param grault [Complex]
            def corge(grault)
              @bar + 0
              @@baz + 0
              QUX + 0
              self.quux + 0
              quux + 0
              grault + 0
            end
          end
        RUBY
      )
    end

    def test_zero_subtraction
      assert_equivalent(
        'module Foo BAR = 1; BAR end',
        <<~RUBY
          module Foo
            # @return [Numeric]
            BAR = 1
            BAR - 0
          end
        RUBY
      )
    end

    def test_unary_negation
      assert_equivalent(
        'module Foo BAR = 1; -BAR end',
        <<~RUBY
          module Foo
            # @return [Numeric]
            BAR = 1
            0 - BAR
          end
        RUBY
      )
    end

    def test_multiplicative_identity
      assert_equivalent(
        'module Foo BAR = 1; BAR end',
        <<~RUBY
          module Foo
            # @return [Numeric]
            BAR = 1
            BAR * 1
          end
        RUBY
      )
    end

    def test_zero_multiplication
      assert_equivalent(
        'module Foo BAR = 1; 0 end',
        <<~RUBY
          module Foo
            # @return [Integer]
            BAR = 1
            0 * BAR
          end
        RUBY
      )
    end

    def test_zero_multiplication_unsafe
      assert_equivalent(
        'module Foo BAR = 1; 0 * BAR; end',
        <<~RUBY
          module Foo
            # @return [Numeric]
            BAR = 1
            0 * BAR
          end
        RUBY
      )
    end

    def test_division_identity
      assert_equivalent(
        'module Foo BAR = 1; BAR; end',
        <<~RUBY
          module Foo
            # @return [Numeric]
            BAR = 1
            BAR / 1
          end
        RUBY
      )
    end

    def test_exponent_identity
      assert_equivalent(
        'module Foo BAR = 1; BAR; end',
        <<~RUBY
          module Foo
            # @return [Numeric]
            BAR = 1
            BAR ** 1
          end
        RUBY
      )
    end

    def test_zero_exponent
      assert_equivalent(
        'module Foo BAR = 1; 1; end',
        <<~RUBY
          module Foo
            # @return [Integer]
            BAR = 1
            BAR ** 0
          end
        RUBY
      )
    end

    def test_zero_exponent_unsafe
      assert_equivalent(
        'module Foo BAR = 1; BAR ** 0; end',
        <<~RUBY
          module Foo
            # @return [Numeric]
            BAR = 1
            BAR ** 0
          end
        RUBY
      )
    end

    def test_unary_plus_no_op
      assert_equivalent(
        'module Foo BAR = 1; BAR; BAR; end',
        <<~RUBY
          module Foo
            # @return [Numeric]
            BAR = 1
            +BAR
            ++BAR
          end
        RUBY
      )
    end

    def test_multiple_negation
      assert_equivalent(
        'module Foo BAR = 1; -BAR; BAR; -BAR; BAR; end',
        <<~RUBY
          module Foo
            # @return [Numeric]
            BAR = 1
            -BAR    # Odd
            --BAR   # Even
            ---BAR  # Odd
            ----BAR # Even
          end
        RUBY
      )
    end

    def test_multiple_negation_parentheses
      assert_equivalent(
        'module Foo BAR = 1; (-BAR); BAR; -(BAR); BAR; end',
        <<~RUBY
          module Foo
            # @return [Numeric]
            BAR = 1
            (-BAR)        # Odd
            -(-BAR)       # Even
            -(-(-BAR))    # Odd
            -(-(-(-BAR))) # Even
          end
        RUBY
      )
    end
  end
end
