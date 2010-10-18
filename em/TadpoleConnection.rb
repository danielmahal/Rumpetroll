require 'json'
require 'Tadpole.rb'
require 'mongo'

class TadpoleConnection

	def initialize(socket, channel, storage)
		@socket = socket
		@storage = storage

		@tadpole = Tadpole.new()
		@last_update = 0;
		@quota = 10;
								
		socket.onopen {
		  		  		  
		  origin = socket.request["Origin"]
      port, ip = Socket.unpack_sockaddr_in(socket.get_peername)
            
      @storage.connected(ip)
      
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
	  @storage.disconnected()
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
    when "authorize"
      authorize_handler(json)
    end    
  end

  def update_handler(json)
    @tadpole.pos.x    = json["x"].to_f rescue 0
    @tadpole.pos.y    = json["y"].to_f rescue 0
    @tadpole.angle    = json["angle"].to_f rescue 0
    @tadpole.momentum = json["momentum"].to_f rescue 0    
    
    name = json["name"]
    name = nil if name && name.include?("@")    
    @tadpole.handle   = (@tadpole.authorized || name || "Guest #{@tadpole.id}").to_s[0...70]
    
    broadcast @tadpole.to_json
  end

  def message_handler(json)
    msg = json["message"].to_s[0...70]
    
    @storage.message(msg,@tadpole)
        	  
	  broadcast( %({"type":"message","id":#{@tadpole.id},"message":#{ msg.to_json }}) )
  end
  
  def authorize_handler(json)    
    #TODO: refactor.
    if json["token"]
      @storage.retrieveSecret(json["token"]) do |secret|
        EventMachine.defer proc {                
          tokens = OAuthTokens.new()
          tokens.request_token    = json["token"]
          tokens.request_verifier = json["verifier"]
          tokens.request_secret   = secret
          auth = generateTwitterAuthenticator(tokens)
          auth.request(:get,"/1/account/verify_credentials.json")
        }, proc { |credentials|
          json = JSON.parse(credentials.body) rescue {};
      	  @tadpole.authorized = "@#{json["screen_name"]}"
      	  Syslog.info("Authenticated ##{@tadpole.id } as #{@tadpole.authorized}")
        }        
      end
    else
      EventMachine.defer proc {
        auth = generateTwitterAuthenticator()
        url = auth.generate_authorize_url()
        return auth, url
      } , proc { |args| auth,auth_url = args             
        @socket.send(%({"type":"redirect","url":#{ auth_url.to_json }}))
        @storage.storeSecret(auth.tokens.request_token, auth.tokens.request_secret)
      }
    end
  end
  	
end