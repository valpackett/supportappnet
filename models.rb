require 'curator'
require 'mongo'

Curator.configure(:mongo) do |config|
  config.environment = "development"
  config.client      = Mongo::Connection.new
  config.database    = "supportadn"
  config.migrations_path = File.expand_path(File.dirname(__FILE__) + "/migrate")
end

class Page
  include Curator::Model
  attr_accessor :id, :adn_id, :name, :author_adn_id
end

class PageRepository
  include Curator::Repository
  indexed_fields :name, :author_adn_id
end
