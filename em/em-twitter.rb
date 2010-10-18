require "twitterOAuth.rb"

module EM
  module Twitter
    
    def self.application=(app)
      @app = app
    end
    def self.storage=(collection)
      @collection = collection
    end
        
    
    def self.getRequest(&block)
      EventMachine.defer(
        proc { 
          auth = TwitterAuthorization.new(@app) 
          auth.generate_authorize_url
          @collection["secrets"].insert({"token" => auth.tokens.request_token, "secret" => auth.tokens.request_secret })
          auth
        },block      
      )
    end
    
    
    def self.verifyRequest(token,verifier,&block)
      EventMachine.defer(
        proc {
          if doc = @collection["secrets"].find_one({ "token" => token })
            @collection["secrets"].remove(doc)
            tokens = OAuthTokens.new()
            tokens.request_verifier = verifier
            tokens.request_token    = doc["token"]
            tokens.request_secret   = doc["secret"]
            auth = TwitterAuthorization.new(@app,tokens)
            #TODO: should actually return authorized TwitterAuthorization not this request:
            auth.request(:get,"/1/account/verify_credentials.json")
          end
        },block
      )
    end

    #TODO: Twitter.getAccess(token,secret)end
    
    
    
  end  
end
