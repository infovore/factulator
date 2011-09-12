require 'rubygems'
require 'sequel'

DB = Sequel.sqlite('factulator.db')

DB.create_table :podcasts do
  primary_key :id
  String :title, :null => false
  String :url, :null => false
  String :page_url, :null => false
  Text :description
  Integer :file_size
  TrueClass :active, :default => true
  DateTime :created_at
  index :created_at
end

