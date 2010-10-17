#!/usr/bin/ruby
# encoding: utf-8

$: << File.dirname(__FILE__) 

require 'rubygems'
require 'storage'
require 'em-websocket'
require 'json'
require 'Tadpole.rb'
require 'TadpoleConnection.rb'
require 'socket'
require 'utils'
require 'syslog'


DEV_MODE = ARGV.include? "--dev"
VERBOSE_MODE = ARGV.include? "--verbose"

WHITELIST = ["http://rumpetroll.com","http://dev.rumpetroll.com","http://www.rumpetroll.com","http://rumpetroll.six12.co"]

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
  	  port, ip = Socket.unpack_sockaddr_in(socket.get_peername)                          	                	  
        	  
      origin = socket.request["Origin"]
  	  if WHITELIST.include?(origin) || DEV_MODE
  	    TadpoleConnection.new(socket, channel)
  	  else
  	    Syslog.warning("Connection from: #{ip}:#{port} at #{origin} did not match whitelist" )
	      socket.close_connection 
  	  end  	  
  		
  	end
  	
  	Syslog.notice "Server started at #{HOST}:#{PORT}."
  end 

rescue Exception => e
  Syslog.err "#{e} at: #{e.backtrace.join(", ")}"
ensure
  Syslog.notice "Server closed."
  Syslog.close()
end

