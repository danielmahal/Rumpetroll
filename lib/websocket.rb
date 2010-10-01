require 'rubygems'
require 'rev/websocket'


class BufferedConnection < Rev::WebSocket
	
	def initialize(arg)
	  super(arg)
    @messageBuffer = []
	end
	
  def flush_messages
    while data = @messageBuffer.shift()
      yield(data)
    end
  end
	
	def on_open
		@host = peeraddr[2];
		puts "connection opened: <#{@host}>";
	end

  def on_message(data)
    @messageBuffer.push(data);
  end

	def on_close
		puts "connection closed: <#{@host}>"				
	end

end
