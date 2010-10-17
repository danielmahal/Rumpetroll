require 'storage'
require 'json'
require 'Tadpole.rb'

class TadpoleConnection

	def initialize(socket, channel)
		@socket = socket
		@tadpole = Tadpole.new()
		@last_update = 0;
		@quota = 10;
								
		socket.onopen {		  		  
		  origin = socket.request["Origin"]
      port, ip = Socket.unpack_sockaddr_in(socket.get_peername)
      Syslog.info "Connection ##{@tadpole.id } from: #{ip}:#{port} at #{origin}"
  		@socket.send(%({"type":"welcome","id":#{@tadpole.id}}))
  		subscribe(channel)
		}		
		
	end
	
	def subscribe(channel)
		@channel = channel
		@id = channel.subscribe {|message| @socket.send(message) }
		@socket.onmessage {|message| process_message(message) }
		@socket.onclose { unsubscribe }
	end
		
	def unsubscribe()
	  broadcast %({"type":"closed","id":#{@tadpole.id}})    
	  Syslog.info "Disconnect ##{@tadpole.id }"
		@channel.unsubscribe(@id)
	end
		
	def broadcast(message)
		@channel << message
	end
	
	def detect_spam
	  now = Time.now.to_f
	  @quota -= 1 if now-@last_update < 0.3
    @last_update = now
    @socket.close_connection(true) if @quota < 0	 
	end
	
	def process_message(data)	  	  	  
	  json = JSON.parse(data) rescue {};

    case json["type"]
    when "update"
      update_handler(json)
    when "message"  
      detect_spam()
      message_handler(json)
    end      
  end

  def update_handler(json)
    @tadpole.pos.x    = json["x"]||0
    @tadpole.pos.y    = json["y"]||0
    @tadpole.angle    = json["angle"]||0
    @tadpole.momentum = json["momentum"]||0
    @tadpole.handle   = (json["name"] || "Guest #{@tadpole.id}").to_s[0...70]
    
    broadcast @tadpole.to_json
  end

  def message_handler(json)
    msg = json["message"].to_s[0...70]
    
    EventMachine.defer {
      Message.create(:body => "#{msg}", :author => @tadpole.handle);
    }    
	  
	  broadcast( %({"type":"message","id":#{@tadpole.id},"message":#{ msg.to_json }}) )
  end
  	
end