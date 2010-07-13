ROOT_DIR = File.expand_path(File.dirname(__FILE__)) unless defined? ROOT_DIR
require "rubygems"

begin
  require "vendor/dependencies/lib/dependencies"
rescue LoadError
  require "dependencies"
end

require "monk/glue"
require "haml"
require "sass"
require "mongo_mapper"

class Main < Monk::Glue
  set :app_file, __FILE__
  use Rack::Session::Cookie
end

# Connect to mongodb
mongo = settings(:mongo)
puts mongo
puts "mongo host= " + mongo[:host]
puts "database used=" + mongo[:database]
puts "port used=" + mongo[:port].to_s
MongoMapper.connection = Mongo::Connection.new(mongo[:host], mongo[:port], :pool_size => 10)
MongoMapper.database = mongo[:database]
if mongo[:username]
  MongoMapper.database.authenticate(mongo[:username], mongo[:password])
end
# Load all application files.
Dir[root_path("app/**/*.rb")].each do |file|
  require file
end

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

Main.run! if Main.run?
