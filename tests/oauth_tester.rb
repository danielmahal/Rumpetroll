#!/usr/bin/ruby

require "../em/twitterOauth.rb"
require "yaml"

settings = File.open( '../data/settings.yaml' ) { |yf| YAML::load( yf ) } 

rumpetrollApp = TwitterApp.new(settings["twitter"]["appKey"],settings["twitter"]["appSecret"])

a = TwitterAuthorization.new(rumpetrollApp)
puts a.generate_authorize_url

#puts a.authorize("er","erer").inspect rescue nil
#
