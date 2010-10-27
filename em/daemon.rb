#!/usr/bin/ruby
# encoding: utf-8

$: << File.dirname(__FILE__) 

require 'rubygems'
require 'em-websocket'
require 'em-mongo'
require 'em-twitter'
require 'mongo'
require 'ConnectionStorage.rb'
require 'TadpoleConnection.rb'
require 'twitterOAuth.rb'
require 'utils'
require 'syslog'
require 'settings'


settings = Settings.new('data/settings.yaml')

DEV_MODE = ARGV.include? "--dev"
VERBOSE_MODE = ARGV.include? "--verbose"


HOST = '0.0.0.0'
PORT = DEV_MODE ? settings[:websockets,:devPort] : settings[:websockets,:port]
WHITELIST = settings[:websockets,:originWhitelist]

if is_port_open?(HOST, PORT)
  msg = "ERROR: #{HOST}:#{PORT} is already open. Cannot start daemon."
  STDERR.puts msg  
  Syslog.open("rumpetrolld") do
    Syslog.err msg
  end  
  exit 1
end

mongodb = Mongo::Connection.new.db("rumpetroll")
messages = mongodb["messages"]
messages.create_index([["location", Mongo::GEO2D]])

Tadpole.resetCount( mongodb["connections"].count() )

EM::Twitter::application = TwitterApp.new(settings[:twitter,:appKey],settings[:twitter,:appSecret],settings[:twitter,:callback])
EM::Twitter::storage     = mongodb["twitter"]


begin
      
  Syslog.open("rumpetrolld")  
  EventMachine.run do        
    db = EM::Mongo::Connection.new.db('rumpetroll')
  	channel = EM::Channel.new
  	
  	EventMachine::WebSocket.start(:host => HOST, :port => PORT, :debug => VERBOSE_MODE) do |socket|  	  
  	  port, ip = Socket.unpack_sockaddr_in(socket.get_peername)
  	  socket.onopen {
  	    origin = socket.request["Origin"]
    	  if WHITELIST.include?(origin) || DEV_MODE
    	    TadpoleConnection.new(socket, channel, ConnectionStorage.new(db))
    	  else
    	    Syslog.warning("Connection from: #{ip}:#{port} at #{origin} did not match whitelist" )
  	      socket.close_connection
    	  end         
  	  }  	  
  	end
    
  	Syslog.notice "Server started at #{HOST}:#{PORT}."
  end 

rescue Exception => e
  Syslog.err "#{e} at: #{e.backtrace.join(", ")}"
  STDERR.puts e,e.backtrace
ensure
  Syslog.notice "Server closed."
  Syslog.close()
end
