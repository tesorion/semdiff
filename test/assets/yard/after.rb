# frozen_string_literal: true

module Foo
  class Bar
    # @return [Numeric]
    attr_accessor :ivar

    # @return [Integer]
    @@cvar = 2
    # @return [Float]
    CONST = 3.0

    class << self
      # @return [Rational]
      attr_accessor :svar
    end

    # @param a [Complex]
    # @param b [Array<Float>]
    def qux(a, b)
      @ivar = (2**2)
      c = a + @ivar
      c += a + @@cvar + CONST
      c += 20 + CONST + 20
      c += @@cvar * 1**0
      d = '1' << '2'
      d = [] << d
      c += (d | b).collect(&:to_i).sum
    end
  end
end
