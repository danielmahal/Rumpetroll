require 'sequel'

DB = Sequel.sqlite('tadpole.db')
DB.create_table? :messages do
  primary_key :id
  
	String :author
  String :body
	DateTime :created_on
end


class Message < Sequel::Model
	plugin :timestamps, :create => :created_on
end