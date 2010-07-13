require 'rubygems'
require 'contest'
require 'rack'
require "rack/test"

require "init"

class SiteTest < Test::Unit::TestCase
  include Rack::Test::Methods

# setups done after every INDIVIDUAL test
  setup do
  end
  
# teardowns done after every INDIVIDUAL test
  teardown do
  end

  def app
    Main
  end
  
  test 'main page' do
    get "/"
  end

# tests grouped under context
  context "" do
    setup do
    end

    teardown do
    end
    
    test "" do
    end

    test "" do
    end
  end
end

