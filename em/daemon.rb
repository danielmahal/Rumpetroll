#!/usr/bin/env ruby
# encoding: utf-8

$: << File.dirname(__FILE__)
rootdir = File.join(File.dirname(__FILE__),'..')

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
require 'trollop'

CLIoptions = Trollop::options do
  banner "Run the Rumpetroll socet server."
  opt :verbose,   "Verbose output"
  opt :dev,   "Run in more lenient development mode"
  opt :port,  "Port to run on", :type => :int, :required  => true
end

DEV_MODE = CLIoptions[:dev]
VERBOSE_MODE = CLIoptions[:verbose]

HOST = '0.0.0.0'
PORT = CLIoptions[:port]
WHITELIST = (ENV["ORIGIN_WHITE_LIST"]||"").split(/\s+/)

if is_port_open?(HOST, PORT)
  msg = "ERROR: #{HOST}:#{PORT} is already open. Cannot start daemon."
  STDERR.puts msg
  Syslog.open("rumpetrolld") do
    Syslog.err msg
  end
  exit 1
end


MONGODB_URI = ENV['MONGO_URL']
if MONGODB_URI
  mongo_client = Mongo::Client.new(MONGODB_URI)
  mongodb = mongo_client.database
  messages = mongodb["messages"]
  #messages.indexes.create_one([["location", Mongo::GEO2D]])
  Tadpole.resetCount( mongodb["connections"].count() )
  EM::Twitter::storage = mongodb["twitter-secrets"]
end

EM::Twitter::application = TwitterApp.new( ENV["TWITTER_APP_KEY"], ENV["TWITTER_APP_SECRET"], ENV["TWITTER_CALLBACK"] )

begin

  Syslog.open("rumpetrolld")
  EventMachine.run do
    db = MONGODB_URI ? Mongo::Client.new(MONGODB_URI).database : nil
  	channel = EM::Channel.new

  	EventMachine::WebSocket.start(:host => HOST, :port => PORT, :debug => VERBOSE_MODE) do |socket|
  	  port, ip = Socket.unpack_sockaddr_in(socket.get_peername)
  	  socket.onopen { |handshake|
    	  if WHITELIST.include?(handshake.origin) || DEV_MODE
          storage = db ? ConnectionStorage.new(db) : nil
    	    TadpoleConnection.new(socket, channel, storage)
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
