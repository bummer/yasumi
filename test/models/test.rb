require 'rubygems'
require 'contest'

class Test < Test::Unit::TestCase
  setup do
    MongoMapper.connection = Mongo::Connection.new("localhost", 27017)
    MongoMapper.database = "test"
    @value = 1
  end

  teardown do
  end

  test "sample test" do
    assert_equal 1, @value
  end
end

