
class Vec2
  
  attr_accessor :x,:y;
  
  def initialize
    @x = 0;
    @y = 0;    
  end
  
  def to_s
    "<#{@x},#{@y}>"
  end  
  
end