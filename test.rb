class Hello
  def fn
    self.class
  end
end

h= Hello.new
p h.fn