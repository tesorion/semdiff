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
      @ivar = 9 / 2
      c = @ivar + a
      c += @@cvar + (CONST + a)
      c += 15 + 5 + CONST
      c += @@cvar / (15 - 14)
      d = '1'.concat('2')
      d = Array.new(0).push(d)
      c += (d | b).map(&:to_i).sum
    end
  end
end
