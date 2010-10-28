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
									  		  		  
    port, ip = Socket.unpack_sockaddr_in(socket.get_peername)            
    Syslog.info "Connection ##{@tadpole.id} from: #{ip}:#{port}"
  	@storage.connected(ip)    
  	@socket.send(%({"type":"welcome","id":#{@tadpole.id}}))
  	subscribe(channel)
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
    when "twitter"
      twitter_handler(json)
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
    return if @authorization_lock 
    @authorization_lock = true;
    if json["token"]
      EM::Twitter.verifyRequest(json["token"],json["verifier"]) { |auth|
        if auth && auth.authorized?
          @auth = auth
          @tadpole.authorized = "@#{auth.screen_name}"
          @tadpole.twitter_id = "#{auth.user_id}"

          @storage.authorized(auth.user_id,auth.screen_name)
          Syslog.info("Authenticated ##{@tadpole.id } as #{@tadpole.authorized}")
          

          @tadpole.handle = @tadpole.authorized
          broadcast @tadpole.to_json          
        else          
  	      @authorization_lock = nil
  	    end
      }
    else
      EM::Twitter.getRequest { |auth| 
        @socket.send(%({"type":"redirect","url":#{ auth.authorize_url.to_json }})) 
        @authorization_lock = nil
      }      
    end
    
  end

  def twitter_response(request,json)
    if json["error"]
        request["result"] = "failure"
    else
        request["result"] = "success"
    end
    @socket.send(request.to_json)
  end

  def twitter_handler(json)
     if @auth && @auth.authorized?
        case json["request"]
        when "follow"
            EM::Twitter.post(@auth,"/friendships/create/#{json['id']}.json") { |result|
                twitter_response(json,result.to_json)        
            }
        when "unfollow"
            EM::Twitter.post(@auth,"/friendships/destroy/#{json['id']}.json") { |result|
                twitter_response(json,result.to_json)        
            }
        when "friends"
            EM::Twitter.get(@auth,"/friends/ids.json") { |result|
                if not result.to_json["error"]
                    @socket.send(%({"type":"twitter","request":"friends","result":#{result}}));
                end
            }
        end
     end
  end

end
