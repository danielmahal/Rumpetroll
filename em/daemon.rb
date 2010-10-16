#!/usr/bin/ruby
# encoding: utf-8

$: << File.dirname(__FILE__) 

require 'rubygems'
require 'storage'
require 'em-websocket'
require 'json'
require 'Tadpole.rb'
require 'socket'
require 'utils'
require 'syslog'


DEV_MODE = ARGV.include? "--dev"
VERBOSE_MODE = ARGV.include? "--verbose"

WHITELIST = ["http://rumpetroll.com","http://dev.rumpetroll.com","http://www.rumpetroll.com","http://rumpetroll.six12.co"]

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
             	  
  	  if WHITELIST.include?(origin) || DEV_MODE
  		  @socket.send(%({"type":"welcome","id":#{@tadpole.id}}))
  		  subscribe(channel)
	    else
	      Syslog.warning("Connection ##{@tadpole.id } from: #{ip}:#{port} at #{origin} did not match whitelist" )
	      socket.close_connection 
      end            
		  		  
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
		# Broadcast message from client
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
    @tadpole.pos.x = json["x"]||0
    @tadpole.pos.y = json["y"]||0
    @tadpole.handle = (json["name"] || "Guest #{@tadpole.id}").to_s[0...45]
    @tadpole.angle = json["angle"]||0
    @tadpole.momentum = json["momentum"]||0
    @tadpole.drive.x  = json["vx"]||0
    @tadpole.drive.y  = json["vy"]||0        
    
    broadcast @tadpole.to_json
  end

  def message_handler(json)
    msg = json["message"].to_s[0...45]
	  Message.create(:body => "#{msg}", :author => @tadpole.handle);          
	  broadcast( %({"type":"message","id":#{@tadpole.id},"message":#{ msg.to_json }}) )
  end
  
	
end

Syslog.open("rumpetrolld")

HOST = '0.0.0.0'
PORT = DEV_MODE ? 8181 : 8180
  
if is_port_open?(HOST, PORT)
  msg = "ERROR: #{HOST}:#{PORT} is already open. Cannot start daemon."
  Syslog.err msg
  STDERR.puts msg
  exit 1
end

begin
  
  EventMachine.run do
  	channel = EM::Channel.new
  	
  	EventMachine::WebSocket.start(:host => HOST, :port => PORT, :debug => VERBOSE_MODE) do |socket|
  		TadpoleConnection.new(socket, channel)
  	end
  	
  	Syslog.notice "Server started at #{HOST}:#{PORT}."
  end 

rescue Exception => e
  Syslog.err "#{e} AT: #{e.backtrace.join(",")}"
ensure
  Syslog.close()
end

