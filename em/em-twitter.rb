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
          @collection["secrets"].insert({"token" => auth.tokens.request_token, "secret" => auth.tokens.request_secret, "created_at" => Time.now.to_f })
          auth
        },block      
      )
    end
        
    def self.verifyRequest(token,verifier,&block)
      EventMachine.defer(
        proc {
          if doc = @collection["secrets"].find_one({ "token" => token })
            @collection["secrets"].remove(doc)
            auth = TwitterAuthorization.new(@app,OAuthTokens.new(doc["token"],doc["secret"],verifier))
            auth.authorize()
            auth
          end
        },block
      )
    end

    def self.restoreSession(session,&block)
      EventMachine.defer(
        proc {
          auth = TwitterAuthorization.new(@app)
          auth.restore_session(session["access_token"],session["access_secret"])
          auth
        },block
      )

    end
    
    def self.session (token,verifier)
        @collection["sessions"].find_one({ "token" => token, "verifier" => verifier})
    end

    def self.storeSession(tokens)
      EventMachine.defer(
        proc {
          unless session(tokens[:request_token],tokens[:request_verifier])
            @collection["sessions"].insert("token" => tokens[:request_token],
                                           "verifier" => tokens[:request_verifier],
                                           "access_token" => tokens[:access_token],
                                           "access_secret" => tokens[:access_secret]
                                          );
          end
        })
    end        

    def self.get(auth,path,&block)
        EventMachine.defer(
            proc {
                result = auth.get(path)
                result  
            },block
        )
    end
    
    def self.post(auth,path,&block)
        EventMachine.defer(
            proc {
                result = auth.post(path)
                result
            },block
        )
    end

  end  
end
