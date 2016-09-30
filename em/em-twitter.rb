require "twitterOAuth.rb"


module EM
  module Twitter

    def self.application=(app)
      @app = app
    end
    def self.storage=(collection)
      @collection = collection
    end

    def self.addSecret(data)
      if @collection
        @collection.insert_one(data)
      else
        #implementation missing
      end
    end

    def self.popSecret(token)
      if @collection
        @collection.find_one_and_delete({ "token" => token })
      else
        #implementation missing
      end
    end

    def self.getRequest(&block)
      EventMachine.defer(
        proc {
          auth = TwitterAuthorization.new(@app)
          auth.generate_authorize_url
          addSecret({"token" => auth.tokens.request_token, "secret" => auth.tokens.request_secret, "created_at" => Time.now.to_f })
          auth
        },block
      )
    end

    def self.verifyRequest(token,verifier,&block)
      EventMachine.defer(
        proc {
          if doc = popSecret(token)
            auth = TwitterAuthorization.new(@app,OAuthTokens.new(doc["token"],doc["secret"],verifier))
            auth.authorize()
            auth
          end
        },block
      )
    end

    #TODO: Twitter.getAccess(token,secret)end
    #TODO: Twitter.request(:post,"command",&block)

  end
end
