require "lib/geometry.rb"
require "lib/enumerableExtensions.rb"
require "thread"
require 'sequel'

# DB = Sequel.sqlite() 
DB = Sequel.sqlite('tadpole.db')
DB.create_table? :messages do
  primary_key :id
  
	String :author
  String :body
	DateTime :created_on
end


class Message < Sequel::Model
	plugin :timestamps, :create => :created_on
end


#message = Message.create(:body => "Lorem")
#message2 = Message.create(:body => "ipsum!", :author => "hp")

class TadpoleAgent
  attr_reader   :knowledge,
                :messages;
  
  attr_accessor :tadpole,
                :alive;
  
  def initialize
    @alive = true;
    @knowledge = []; 
    @messages = [];
  end
  
  def push    
    ##override;
    #Send knowledge to Agent.
  end
  def pull    
    ##override;
    #Get update from Agent.
  end
end


class TadpoleConnectionAgent < TadpoleAgent
  
  def initialize(buffer)
    super();
    @buffer = buffer;
  end
  
  def pull
    messages.clear
    @buffer.flush_messages do |data|
      obj = JSON.parse(data);
      
      
      if (obj["type"] == "update")
        @tadpole.pos.x = obj["x"] || 0;
        @tadpole.pos.y = obj["y"] || 0;
        @tadpole.handle = obj["name"] || "Guest #{@tadpole.id}";        
        @tadpole.angle = obj["angle"] || 0;
        @tadpole.momentum = obj["momentum"] || 0;

        @tadpole.drive.x  = obj["vx"]||0;
        @tadpole.drive.y  = obj["vy"]||0;        
      elsif (obj["type"] == "message")
                            
        Message.create(:body => "#{obj["message"]}", :author => @tadpole.handle);
        
        messages.push obj["message"];
        
      end
      
      # tick()
    end
  end

  def push    
        
    @knowledge.push(@tadpole)
    while t = @knowledge.pop
      @buffer.send_message( t.to_json ) 
      t.agent.messages.each do |m|
        @buffer.send_message( %({"type":"message","id":#{t.id},"message":"#{m}"}) )
      end                                        
    end    
    
  end
  
  def welcome()
    @buffer.send_message( %({"type":"welcome","id":#{@tadpole.id}}) );            
  end
  
  def tick
    @buffer.send_message( %({"type":"tick"}) );            
  end
  
end

class Tadpole
  
  @@count = 0
  
  attr_reader   :id,:agent;
  attr_accessor :drive,:pos,:momentum,:angle,:life,:handle;
  
  def initialize(agent)
    @id = @@count;
    @@count += 1;
    
    @agent = agent;    
    @drive = Vec2.new();
    @pos = Vec2.new();
    @life = 1;
    @angle = 0;
    @momentum = 0;
  end
  
  def update()
            
    @pos.x += @drive.x
    @pos.y += @drive.y
    @angle = Math.atan2(@drive.y,@drive.x)
    @momentum = Math.sqrt(@drive.y*@drive.y+@drive.x*@drive.x)
    
  end
  
  def to_s
    "[Tadpole #{@id} #{@pos}]"
  end
  
  def to_json
    if (@agent.alive) 
      @life = 0 if @life < 0
      %({"type":"update","id":#{@id},"angle":#{@angle||"0"},"momentum":#{@momentum||"0"},"x":#{@pos.x||"0"},"y":#{@pos.y||"0"},"life":#{@life||"0"},"name":"#{@handle}"})
    else
      %({"type":"closed","id":#{@id}})
    end    
  end
  
end

PI2 = Math::PI*2


class TadpoleSystem

  attr_reader :tadpoles
  
  def initialize()    
    @tadpoles = []
    @semaphore = Mutex.new
  end
  
  def createTadpole(agent)
    t = Tadpole.new(agent)
    agent.tadpole = t
    agent.welcome if agent.respond_to?(:welcome)
    
    # t.pos.x = rand() * 200;
    # t.pos.y = rand() * 200;
    
    @semaphore.synchronize { @tadpoles.push(t) }      
  end
    
  def update()
    @semaphore.synchronize do
      @tadpoles.each do |t|
        t.agent.pull if t.agent
      end
          
      blindZone     = 1000*1000 # blindzone squared.    
      collisionZone = 15*15 # collisionzone squared.    
      
      def radDiff(a)
        while(a < -Math::PI) 
            a += PI2;
        end
        while(a > Math::PI)
          a -= PI2;
        end
        a        
      end
      
      @tadpoles.compare_all do |a,b|
        
        # distance_squared = (a.pos.x-b.pos.x)**2 + (a.pos.y-b.pos.y)**2
        
        # if (distance_squared < blindZone)        
          a.agent.knowledge.push(b)
          b.agent.knowledge.push(a)
                  
          ##puts "b #{bd} , a #{ad}       "
                    
          # if (distance_squared < collisionZone)
          #             
          #             bn = Math.atan2(a.pos.y-b.pos.y, a.pos.x-b.pos.x) #angle from b.pos to a.pos
          #             an = radDiff(bn-Math::PI) #angle from a.pos to b.pos
          #             
          #             bd = radDiff(b.angle-bn); #Difference between b.angle and angle from b.pos to a.pos
          #             ad = radDiff(a.angle-an); #Difference between a.angle and angle from a.pos to b.pos
          #                                     
          #             damageFromB = 0.1*(1-bd.abs/Math::PI) * (1+b.momentum) *0.2;
          #             damageFromA = 0.1*(1-ad.abs/Math::PI) * (1+a.momentum) *0.2;
          #             
          #             
          #             # ad = 0.1*(1+b.momentum) * ad
          #             # bd = 0.1*(1+a.momentum) * bd
          #             
          #             damageFromB = 0 if damageFromB<0
          #             damageFromA = 0 if damageFromA<0
          #             
          #             # puts "Damage dealt  #{damageFromA} <=> #{damageFromB}"
          #             
          #             
          #             a.life -= damageFromB;
          #             b.life -= damageFromA;
          #             
          #           end
                  
        
          
        # end
      end
      
      @tadpoles.reject! do |t|
        #t.update()
        t.agent.push
        !t.agent.alive        
      end
    end
  end
    
end
