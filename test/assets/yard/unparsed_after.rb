# frozen_string_literal: true
module Foo
  class Bar
    # @return [Numeric]
    attr_accessor(:ivar)
    # @return [Integer]
    @@cvar = 2
    # @return [Float]
    CONST = 3.0

    class << self
      # @return [Rational]
      attr_accessor(:svar)
    end

    # @param a [Complex]
    # @param b [Array<Float>]
    def qux(a, b)
      @ivar = 4
      c = @ivar + a
      c = c + @@cvar.+(CONST).+(a)
      c = c + 40.+(CONST)
      c = c + @@cvar
      d = "1" << "2"
      d = [] << d
      c = c + (d | b).map(&:to_i).sum
    end
  end
end
