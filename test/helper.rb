$:.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'test/unit/assertions'
require 'mocha/setup'
require 'redfish'

class Redfish::TestCase < Minitest::Test
  include Test::Unit::Assertions

  def setup
  end

  def teardown
  end
end
