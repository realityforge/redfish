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

  def create_simple_context(executor)
    Redfish::Context.new(executor, '/opt/payara-4.1.151/', 'domain1', 4848, false, 'admin', nil)
  end
end
