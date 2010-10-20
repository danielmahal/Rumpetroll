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
    store_doc
  end    
  
  def disconnected
    if @isConnected
      @doc[:end] = Time.now
	    store_doc
    end
  end
  
  def authorized(user_id,screen_name)
    @doc[:user_id] = user_id
    @doc[:screen_name] = screen_name
    store_doc
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
  
  private 
  
  def store_doc
    if id = @doc["_id"]
      @connections.update({ "_id" => id }, @doc)
    else
      @connections.insert(@doc)
    end
  end
  
end
