require 'em-mongo'

class ConnectionStorage
  
  
  
  def initialize(db)
    @db = db
		@connections = db.collection('connections')
		@messages = db.collection('messages')
		@secrets = db.collection('secrets')
		@doc = {}		
  end
  
  def connected(ip)
    return if @isConnected
    @isConnected = true 
    @doc[:ip] = ip
    @doc[:start] = Time.now
    @connections.insert(@doc)    
  end    
  
  def disconnected
    if @isConnected
      @doc[:end] = Time.now
	    @connections.update({ "_id" => @doc["_id"] }, @doc)
    end
  end
    
  def message(body,tadpole)
    @messages.insert( {
      :created_on => Time.now,
      :connection_id => @doc["_id"].to_s,
      :body => body,      
      :author => tadpole.handle,
      :location => [tadpole.pos.x,tadpole.pos.y]
    })
  end
  
end
