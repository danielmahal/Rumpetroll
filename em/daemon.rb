#!/usr/bin/ruby
# encoding: utf-8

$: << File.dirname(__FILE__) 

require 'rubygems'
require 'storage'
require 'em-websocket'
require 'json'
require 'Tadpole.rb'
require 'socket'


DEV_MODE = ARGV[0] == "dev"
WHITELIST = ["http://rumpetroll.com","http://dev.rumpetroll.com","http://www.rumpetroll.com","http://rumpetroll.six12.co"]

class TadpoleConnection
	def initialize(socket, channel)
		@socket = socket
		@tadpole = Tadpole.new()
						
		socket.onopen {
		  
		  origin = socket.request["Origin"]		  
      port, ip = Socket.unpack_sockaddr_in(socket.get_peername)                          	                	  
      
      puts "Connection ##{@tadpole.id } from: #{ip}:#{port} at #{origin}" 
             	  
  	  if WHITELIST.include?(origin) || DEV_MODE
  		  @socket.send(%({"type":"welcome","id":#{@tadpole.id}}))
  		  subscribe(channel)
	    else
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
	  puts "Disconnect ##{@tadpole.id }"
		@channel.unsubscribe(@id)
	end
		
	def broadcast(message)
		# Broadcast message from client
		@channel << message
	end
	
	def process_message(data)
	  json = JSON.parse(data) rescue {};
    
    case json["type"]
    when "update"
      update_handler(json)
    when "message"  
      message_handler(json)
    end      
  end

  def update_handler(json)
    @tadpole.pos.x = json["x"]||0
    @tadpole.pos.y = json["y"]||0
    @tadpole.handle = (json["name"] || "Guest #{@tadpole.id}")[0...45]
    @tadpole.angle = json["angle"]||0
    @tadpole.momentum = json["momentum"]||0
    @tadpole.drive.x  = json["vx"]||0
    @tadpole.drive.y  = json["vy"]||0        
    
    broadcast @tadpole.to_json
  end

  def message_handler(json)
    msg = json["message"]
    msg = msg[0...45]        
    
    Message.create(:body => "#{msg}", :author => @tadpole.handle);  
        
    broadcast( %({"type":"message","id":#{@tadpole.id},"message":#{ msg.to_json }}) )
  end
  
	
end

EventMachine.run do
	host = '0.0.0.0'
	port = 8180
	channel = EM::Channel.new
	
	EventMachine::WebSocket.start(:host => host, :port => port, :debug => DEV_MODE) do |socket|
		TadpoleConnection.new(socket, channel)
	end
	
	puts "Server started at #{host}:#{port}."
end
