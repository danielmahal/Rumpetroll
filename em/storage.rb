require 'sequel'

STORAGE_DIR = "#{File.dirname(__FILE__)}/../data"
Dir.mkdir STORAGE_DIR unless File.exists? STORAGE_DIR

DB = Sequel.sqlite("#{STORAGE_DIR}/tadpole.db")
DB.create_table? :messages do
  primary_key :id
  
	String :author
  String :body
	DateTime :created_on
end


class Message < Sequel::Model
	plugin :timestamps, :create => :created_on
end

