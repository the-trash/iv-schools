class String
  def sharps2anchor!
    # "Hello World! ###world I'm String!".sharps2anchor! => Hello World! <a href="#world" title="#world"></a> I'm String!
    self.gsub!(/ ###(\S*) /, " <a href=\"#\\1\" title=\"#\\1\"></a> ")
  end
end

str = "Hello World! ###world I'm String!"
puts str
puts str.sharps2anchor!