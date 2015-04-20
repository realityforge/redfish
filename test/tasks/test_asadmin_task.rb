require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestAsadminTask < Redfish::TestCase
  def test_load_properties
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.
      expects(:exec).
      with(equals(t.context), equals('get'), equals(%w(*)), equals(:terse => true, :echo => false)).
      returns("a=1\nb=2\nc.d.e=345")

    properties = t.send(:load_properties, '*')

    assert_equal properties['a'], '1'
    assert_equal properties['b'], '2'
    assert_equal properties['c.d.e'], '345'
  end

  def test_parse_properties
    executor = Redfish::Executor.new
    t = new_task(executor)

    properties = t.send(:parse_properties, "a=1\nb=2\nc.d.e=345")

    assert_equal properties['a'], '1'
    assert_equal properties['b'], '2'
    assert_equal properties['c.d.e'], '345'
  end

  def new_task(executor)
    t = Redfish::Tasks::AsadminTask.new
    t.context = Redfish::Context.new(executor, '/opt/payara-4.1.151/', 'domain1', 4848, false, 'admin', nil)
    t
  end
end
