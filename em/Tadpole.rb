require "geometry.rb"

class Tadpole
    
  @@count = 0
  def self.resetCount(newCount=nil)
    @@count = newCount || 0
  end
  
  attr_reader   :id

  attr_accessor :drive,
                :pos,
                :momentum,
                :angle,
                :handle,
                :authorized
  
  def initialize()
    @id = @@count += 1

        
    @pos = Vec2.new();
    @drive = Vec2.new();
    @life = 1;
    @angle = 0;
    @momentum = 0;
    @authorized = nil;
  end
  
  ##def update()   
  ##  @pos.x += @drive.x
  ##  @pos.y += @drive.y
  ##  @angle = Math.atan2(@drive.y,@drive.x)
  ##  @momentum = Math.sqrt(@drive.y*@drive.y+@drive.x*@drive.x)                 
  ##end
  
  def to_s
    "[Tadpole #{@id} #{@pos}]"
  end
  
  def to_json
    %({"type":"update","id":#{@id},"angle":#{@angle||"0"},"momentum":#{@momentum||"0"},"x":#{@pos.x||"0"},"y":#{@pos.y||"0"},"life":#{@life||"0"},"name":"#{@handle}", "authorized":#{@authorized!=nil}})
  end
  
end
