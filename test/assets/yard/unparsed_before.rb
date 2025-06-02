module Foo
  class Bar
    attr_accessor(:ivar)
    @@cvar = 2
    CONST = 3.0

    class << self
      attr_accessor(:svar)
    end

    def qux(a, b)
      @ivar = 4
      c = @ivar + a
      c = c + @@cvar.+(CONST).+(a)
      c = c + CONST.+(20)
      c = c + @@cvar
      d = "1" << "2"
      d = [] << d
      c = c + (d | b).map(&:to_i).sum
    end
  end
end
