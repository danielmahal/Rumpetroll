require "lib/TadpoleSystem.rb"


class AIAgent < TadpoleAgent
  
  def initialize()
    super()
#    @age = rand()*Math::PI*2
#    @direction = (rand()-0.5)/10;
    @direction = 0
    @age = 0
  end
  
  def push
    @knowledge.clear
  end
  def pull
    
    if @tadpole 
      
      @age+=1
      @tadpole.momentum = 3;      
      @tadpole.angle = @direction;
            
      @tadpole.pos.x += Math.cos(@tadpole.angle)*@tadpole.momentum;
      @tadpole.pos.y += Math.sin(@tadpole.angle)*@tadpole.momentum;      
      
      if @tadpole.pos.x > 1200 || @tadpole.pos.x < -1200
        @direction += Math::PI
      end
        
      
    end    
  end
end
