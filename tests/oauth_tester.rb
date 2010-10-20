#!/usr/bin/ruby

require "../em/twitterOauth.rb"
require "../em/settings.rb"
require "yaml"




settings = Settings.new('../data/settings.yaml')

rumpetrollApp = TwitterApp.new(settings[:twitter,:appKey],settings[:twitter,:appSecret],"http://localhost")

TOKENS_FILE = "tokens2.yaml"

if File.exists? TOKENS_FILE
  tokens = File.open( TOKENS_FILE ) { |yf| YAML::load( yf ) }
  a = TwitterAuthorization.new(rumpetrollApp,tokens)
  puts a.screen_name
  puts a.request(:get,"/1/account/verify_credentials.json")
  puts a.screen_name

  
else 
  a = TwitterAuthorization.new(rumpetrollApp)
  puts a.generate_authorize_url()
end


File.open( TOKENS_FILE, 'w' ) do |out|
  YAML.dump( a.tokens, out )
end
