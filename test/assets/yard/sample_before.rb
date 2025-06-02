class Foo
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
end
