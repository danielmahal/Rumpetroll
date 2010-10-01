
require 'lib/debugTools.rb'
require 'rubygems'
require 'json'
require 'lib/websocket.rb'
require "lib/TadpoleSystem.rb"
require "lib/npcTadpoles.rb"

$TADPOLE_SYSTEM = TadpoleSystem.new();

class TadpoleConnection < BufferedConnection
        
  def on_open
    super()
    @agent = TadpoleConnectionAgent.new(self);
    $TADPOLE_SYSTEM.createTadpole(@agent);              
	end
	
	def on_close
	  super()
	  @agent.alive = false if @agent;
	end
	  
end 

host = '0.0.0.0'
port = 8180

server = Rev::WebSocketServer.new(host, port, TadpoleConnection)
server.attach(Rev::Loop.default)

puts "start on #{host}:#{port}"

Thread.new() do
  
  loopcount = 0
  accum = 0
  
   while true
     begin
       startTime = Time.new;

       $TADPOLE_SYSTEM.update();
       
       updateTime = Time.new-startTime       
       accum += updateTime
       if (loopcount % 1000 == 0)          
         puts "Average update:, #{accum*0.001} sec"
         accum = 0
       end
       if (loopcount % 20000 == 0) 
         # Sampler::sample         
       end
       loopcount += 1
       sleep 0.1;
     rescue Exception => e
       puts "ERROR #{e}",e.backtrace
       exit 0
     end     
          
   end 
end

0.times do
    $TADPOLE_SYSTEM.createTadpole(AIAgent.new);
end



Rev::Loop.default.run
