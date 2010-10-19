require 'rubygems'
require 'oauth'

OAuthTokens = Struct.new(:request_token, :request_secret, :request_verifier, :access_token, :access_secret)

class TwitterApp
  
  attr_reader :key,:secret,:options
  attr_accessor :default_callback
  
  def initialize(key,secret,callback,options={})
    @key = key
    @secret = secret
    @default_callback = callback
    @options = {
      :site=>"https://api.twitter.com"
    }.merge(options)
  end
  
end

class TwitterAuthorization
  
  attr_reader :tokens,:authorize_url

  def initialize(app,tokens=nil)
    
    @app      = app
    @tokens   = tokens || OAuthTokens.new()
    @consumer = OAuth::Consumer.new(app.key,app.secret,app.options)
    
  end
  
  def generate_authorize_url(options={})
    @authorize_url = nil
    options[:oauth_callback] ||= @app.default_callback
    request_token = @consumer.get_request_token( options )
    @tokens.request_token = request_token.token
    @tokens.request_secret = request_token.secret
    @authorize_url = request_token.authorize_url
  end
    
  def authorize(request_token,request_verifier)
    @tokens.request_token = request_token
    @tokens.request_verifier = request_verifier
    access_token
  end
  
  def request(*args)
    at = access_token
    at.request(*args) if at
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