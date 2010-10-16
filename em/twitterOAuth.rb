require 'rubygems'
require 'oauth'

class OAuthTokens
  
  attr_accessor :request_token,
                :request_secret,
                :request_verifier,
                :access_token,
                :access_secret
  
end

class TwitterApp
  
  attr_reader :key,:secret,:options  
  
  def initialize(key,secret,&options)
    @key = key
    @secret = secret
    @options = {
      :site=>"https://api.twitter.com"
    }.merge(options||{})    
  end
  
end

class TwitterAuthorization
  
  attr_reader :tokens

  def initialize(app,tokens=nil)
    
    @consumer = OAuth::Consumer.new(app.key,app.secret,app.options)
    @tokens   = tokens || OAuthTokens.new()
    
  end
  
  def generate_authorize_url(options={})
    request_token = @consumer.get_request_token( options )
    @tokens.request_secret = request_token.secret
    request_token.authorize_url
  end
    
  def authorize(request_token,request_verifier)
    @tokens.request_token = request_token
    @tokens.request_verifier = request_verifier
    access_token
  end
    
  private
    
    def access_token
      unless @access_token
        if @tokens.access_token && @tokens.access_secret
          @access_token = OAuth::AccessToken.new(@consumer, @tokens.access_token, @tokens.access_secret)
        elsif @tokens.request_token && @tokens.request_secret && @tokens.request_verifier
          request_token = OAuth::RequestToken.new(@consumer, @tokens.request_token, @tokens.request_secret )
          @access_token = request_token.get_access_token(:oauth_verifier => @tokens.request_verifier)
          @tokens.access_token = @access_token.token
          @tokens.access_secret = @access_token.secret
        end
      end
      @access_token
    end
  
end