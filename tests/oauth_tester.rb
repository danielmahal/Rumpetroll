#!/usr/bin/ruby

require "../em/twitterOauth.rb"
require "yaml"
require "syslog"

settings = File.open( '../data/settings.yaml' ) { |yf| YAML::load( yf ) } 

rumpetrollApp = TwitterApp.new(settings["twitter"]["appKey"],settings["twitter"]["appSecret"])

TOKENS_FILE = "tokens1.yaml"

if File.exists? TOKENS_FILE
  tokens = File.open( TOKENS_FILE ) { |yf| YAML::load( yf ) }
  a = TwitterAuthorization.new(rumpetrollApp,tokens)
  puts a.request(:get,"/1/account/verify_credentials.json")
else 
  a = TwitterAuthorization.new(rumpetrollApp)
  puts a.generate_authorize_url(:oauth_callback => "http://localhost")
end


File.open( TOKENS_FILE, 'w' ) do |out|
  YAML.dump( a.tokens, out )
end
