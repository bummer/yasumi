ROOT_DIR = File.expand_path(File.dirname(__FILE__)) unless defined? ROOT_DIR
RACK_ENV = :development unless defined? RACK_ENV

# load dependencies
File.read("config/deps").each_line do |line|
  args = line.split ' '
  next unless args.length >= 2
  name = args[0]
  version = args[1]
  begin
    if $:.unshift(File.expand_path(Dir[File.join("vendor", "#{name}-#{version}*", "lib")].first || Dir[File.join("vendor", name, "lib")].first))
    else 
      gem(*[args[0], args[1]].compact)
      puts name + " loaded from local gems"
    end
  rescue Gem::LoadError => e
    fail name + " failed to load: " + e.inspect
  end
end

require "rubygems"
require "sinatra/base"
require 'yaml'

require "haml"
require "sass"
require 'rack/openid'
require 'rack/offline'
require 'rack/html5'
require 'rack/throttle'

require "mongo_mapper"

require 'bunyan'

require 'warden'

# common functions
def path_of(path="/")
  File.join(ROOT_DIR, path)
end

def log(items)
  if items.instance_of? String
    Bunyan::Logger.insert 'message'=>items, 'type'=>'info', 'time'=>Time.now.to_s
    puts items
  else
    items.each do |typ, msg|
      Bunyan::Logger.insert 'message'=>msg, 'type'=>typ.to_s, 'time'=>Time.now.to_s
    end
  end
end

$settings ||= YAML.load_file(path_of("config/settings.yml"))[RACK_ENV]

class Main < Sinatra::Base

  # set sinatra options
  set :dump_errors,     true
  set :logging,         true
  set :methodoverride,  true
  set :raise_errors,    test? || development?
  set :root,            path_of
  set :environment,     RACK_ENV
  set :run,             development?
  set :show_exceptions, development?
  set :static,          true
  set :views,           path_of("app/views")
  set :app_file,        __FILE__
  
  # reloading if in development mode
  if development?
    require 'sinatra/reloader'
    register Sinatra::Reloader
    # also_reload "app/models/*.rb"
    # dont_reload "lib/**/*.rb"
    log 'reloading on'
  end

  # add Rack middleware
  use Rack::Session::Cookie
  use Rack::OpenID
  use Rack::Html5 unless test?
    #  Rack::Html5 sets the following HTTP headers:
      # HTTP_X_DETECTED_BROWSER: Browser that has been DETECTED, eg.: Firefox
      # HTTP_X_DETECTED_VERSION: Version of the browser that has been DETECTED, eg.: 3.6.6
      # HTTP_X_SUPPORTS_HTML5_WYSIWYG: WYSIWYG editable elements
      # HTTP_X_SUPPORTS_HTML5_CLASSNAME: getElementsByClassName
      # HTTP_X_SUPPORTS_HTML5_ELEMENTS: Stylable HTML5 elements
      # HTTP_X_SUPPORTS_HTML5_CANVAS: Canvas (basic support)
      # HTTP_X_SUPPORTS_HTML5_MESSAGING: Cross-document messaging
      # HTTP_X_SUPPORTS_HTML5_AUDIO: Audio element
      # HTTP_X_SUPPORTS_HTML5_VIDEO: Video element
      # HTTP_X_SUPPORTS_HTML5_TEXTAPI: Text API for canvas
      # HTTP_X_SUPPORTS_HTML5_DRAGANDDROP: Drag and drop
      # HTTP_X_SUPPORTS_HTML5_OFFLINE: Offline web applications
      # HTTP_X_SUPPORTS_HTML5_SVG: Inline SVG
      # HTTP_X_SUPPORTS_HTML5_FORMS: Form features (Web Forms 2.0)

  # throttle IP in production envt
  if $settings[:cache]
    run Rack::Offline.new {
      # cache "stylesheets/style.css"
      # cache "images/masthead.jpg"
      # cache "javascripts/application.js"
      # cache "javascripts/jquery.js"
      network "/"
    }  
    log "app cacheing in use"
  end
  
  # throttle IP in production envt
  if $settings[:ipthrottle]
    use Rack::Throttle::Daily,    :max => $settings[:ipthrottle][:dailymax].to_i  # requests
    use Rack::Throttle::Hourly,   :max => $settings[:ipthrottle][:hourlymax].to_i   # requests
    if $settings[:ipthrottle][:interval]
      use Rack::Throttle::Interval, :min => $settings[:ipthrottle][:interval].to_f   # seconds  
    end
    log "IP throttling in use"
  end
  
  # configure basic auth
  use Warden::Manager do |manager|
    manager.default_strategies :password, :basic
    #manager.failure_app = app
  end
  Warden::Manager.serialize_into_session do |user|
    #user.id
  end
  Warden::Manager.serialize_from_session do |id|
    #User.get(id)
  end

end

# Setup Bunyan logging
Bunyan::Logger.configure do |config|
  config.database   'logs'
  config.collection RACK_ENV.to_s + '_log'
end

# Connect to mongodb
mongo = $settings[:mongo]
log "environment= " + RACK_ENV.to_s
log "mongo host= " + mongo[:host]
log "database used=" + mongo[:database]
log "port used=" + mongo[:port].to_s
MongoMapper.connection = Mongo::Connection.new(mongo[:host], mongo[:port], :pool_size => 10, :slave_ok => true)
MongoMapper.database = mongo[:database]
if mongo[:username]
  MongoMapper.database.authenticate(mongo[:username], mongo[:password])
end

# Load all application files.
Dir[path_of("app/**/*.rb")].each do |file|
  require file
end

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

# in development, self run, else Main is run via config.ru
Main.run! if Main.run?

