require 'curator'
require 'uri'
require 'mongo'

mongolab_uri = ENV['MONGOLAB_URI']
unless mongolab_uri.nil?
  uri  = URI.parse mongolab_uri
  conn = Mongo::Connection.from_uri mongolab_uri
  db   = uri.path.gsub /^\//, ''
else
  conn = Mongo::Connection.new
  db   = "supportadn"
end

Curator.configure(:mongo) do |config|
  config.environment = "development"
  config.client      = conn
  config.database    = db
  config.migrations_path = File.expand_path(File.dirname(__FILE__) + "/migrate")
end

class Page
  include Curator::Model
  attr_accessor :id, :adn_id, :name, :fullname, :author_adn_id, :archive
end

class PageRepository
  include Curator::Repository
  indexed_fields :name, :author_adn_id
end
