require 'em-mongo'

class ConnectionStorage
  
  
  
  def initialize(db)
    @db = db
		@connections = db.collection('connections')
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
  
  
end