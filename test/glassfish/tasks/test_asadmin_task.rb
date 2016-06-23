#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path('../../../helper', __FILE__)

class Redfish::Tasks::Glassfish::TestAsadminTask < Redfish::TestCase
  class MyAsadminTask < Redfish::Tasks::Glassfish::AsadminTask
    attribute :properties, :kind_of => Hash, :default => {}
  end

  def test_reload_property
    key = 'configs.config.server-config.java-config.jvm-options'

    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(key => 'X')

    executor.
      expects(:exec).
      with(equals(t.context), equals('get'), equals([key]), equals(:terse => true, :echo => false)).
      returns("#{key}=Y\n")

    t.send(:reload_property, key)

    assert_equal t.context.property_cache[key], 'Y'
  end

  def test_reload_properties_with_prefix
    prefix = "applications.application.#{self.name}.module."

    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('outside' => 'blah', "#{prefix}x" => "ZZZ", "#{prefix}a" => "ZZZ")

    executor.
      expects(:exec).
      with(equals(t.context), equals('get'), equals(%W(#{prefix}*)), equals(:terse => true, :echo => false)).
      returns("#{prefix}a=1\n#{prefix}b=2\n#{prefix}c.d.e=345")

    t.send(:reload_properties_with_prefix, prefix)

    assert_equal t.context.property_cache['outside'], 'blah'
    assert_equal t.context.property_cache["#{prefix}x"], ''
    assert_equal t.context.property_cache["#{prefix}a"], '1'
    assert_equal t.context.property_cache["#{prefix}b"], '2'
    assert_equal t.context.property_cache["#{prefix}c.d.e"], '345'
  end

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

  def test_load_property
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.
      expects(:exec).
      with(equals(t.context), equals('get'), equals(%w(some.key)), equals(:terse => true, :echo => false)).
      returns('some.key=345')

    v = t.send(:load_property, 'some.key')
    assert_equal v, '345'
  end

  def test_get_property_no_cache
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.
      expects(:exec).
      with(equals(t.context), equals('get'), equals(%w(some.key)), equals(:terse => true, :echo => false)).
      returns('some.key=345')

    v = t.send(:get_property, 'some.key')
    assert_equal v, '345'
  end

  def test_get_property_with_cache
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('some.key' => '345')

    v = t.send(:get_property, 'some.key')
    assert_equal v, '345'
  end

  def test_parse_properties
    t = new_task

    properties = t.send(:parse_properties, "a=1\nb=2\nc.d.e=345")

    assert_equal properties['a'], '1'
    assert_equal properties['b'], '2'
    assert_equal properties['c.d.e'], '345'
  end

  def collect_property_sets_with_cache_present
    property_prefix = 'resources.jdbc-connection-pool.MyDbPool.'

    t = new_task

    cache_values = {}
    cache_values["#{property_prefix}property.c"] = '3'

    t.context.cache_properties(cache_values)

    t.properties = {'a' => '1', 'b' => '2'}

    property_map = []

    t.send(:collect_property_sets, property_prefix, property_map)

    assert_equal property_map, {'property.a' => '1', 'property.b' => '2', 'property.c' => ''}
  end

  def collect_property_sets_with_no_cache_present
    property_prefix = 'resources.jdbc-connection-pool.MyDbPool.'

    executor = Redfish::Executor.new
    t = new_task(executor)

    # Return a property that should be deleted
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%w(resources.jdbc-connection-pool.APool.property.*)), equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.c=3\n")

    t.properties = {'a' => '1', 'b' => '2'}

    property_map = []

    t.send(:collect_property_sets, property_prefix, property_map)

    assert_equal property_map, {'property.a' => '1', 'property.b' => '2', 'property.c' => ''}
  end

  def new_task(executor = Redfish::Executor.new)
    t = MyAsadminTask.new
    t.run_context = Redfish::RunContext.new(create_simple_context(executor))
    t
  end
end
