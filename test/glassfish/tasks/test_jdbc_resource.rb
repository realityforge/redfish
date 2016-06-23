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

class Redfish::Tasks::Glassfish::TestJdbcResource < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_interpret_create
    data = {'jdbc_connection_pools' => {'MyDBPool' => {'resources' => resource_parameters_as_tree}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('create-jdbc-connection-pool'),
                                 anything,
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('create-jdbc-resource'),
                                 equals(['--enabled', 'true', '--connectionpoolid', 'MyDBPool', '--description', 'Audit DB', 'jdbc/MyDB']),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :create, :additional_task_count => 1, :additional_unchanged_task_count => 1 + 1)
  end

  def test_interpret_create_when_exists
    data = {'jdbc_connection_pools' => {'MyDBPool' => {'resources' => resource_parameters_as_tree}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    executor.expects(:exec).with(equals(context),
                                 equals('create-jdbc-connection-pool'),
                                 anything,
                                 equals({})).
      returns('')

    setup_interpreter_expects(executor, context, to_properties_content)

    perform_interpret(context, data, false, :create, :additional_task_count => 1, :additional_unchanged_task_count => 1 + expected_local_properties.size)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    assert_equal t.to_s, 'jdbc_resource[MyDBPool::jdbc/MyDB]'
  end

  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-resource'),
                                 equals(['--enabled', 'true', '--connectionpoolid', 'MyDBPool', '--description', 'Audit DB', 'jdbc/MyDB']),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context), equals('get'),
                                 equals(["#{property_prefix}deployment-order"]),
                                 equals(:terse => true, :echo => false)).
      returns("#{property_prefix}deployment-order=100\n")

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("jdbc/MyDB\n")
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns('')

    expected_local_properties.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("jdbc/MyDB\n")
    # Return a property that should be deleted
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.Blah=Y\n")

    values = expected_local_properties
    values['deployment-order'] = '101'
    values['enabled'] = 'false'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}enabled=true"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}deployment-order=100"]),
                                 equals(:terse => true, :echo => false))

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(["#{property_prefix}property.Blah"]),
                                 equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.Blah=X\n")

    # This is the set to remove property that should not exist
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.Blah="]),
                                 equals(:terse => true, :echo => false)).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-resource'),
                                 equals(['--enabled', 'true', '--connectionpoolid', 'MyDBPool', '--description', 'Audit DB', 'jdbc/MyDB']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present_but_modified
    cache_values = expected_properties

    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values["#{property_prefix}enabled"] = 'false'
    cache_values["#{property_prefix}description"] = 'XXX'
    cache_values["#{property_prefix}deployment-order"] = '101'

    # This property should be removed
    cache_values["#{property_prefix}property.Blah"] = 'X'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.Blah="]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}deployment-order=100"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}description=Audit DB"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}enabled=true"]),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)

    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present
    t = new_task

    t.context.cache_properties(expected_properties)

    t.options = resource_parameters

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)

    ensure_expected_cache_values(t)
  end

  def test_delete_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'jdbc/MyDB'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jdbc-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'jdbc/MyDB'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jdbc-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("jdbc/MyDB\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jdbc-resource'),
                                 equals(['jdbc/MyDB']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'jdbc/MyDB'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'jdbc/MyDB'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jdbc-resource'),
                                 equals(['jdbc/MyDB']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_interpret_create_and_delete
    data = {'jdbc_connection_pools' => {'MyDBPool' => {'resources' => resource_parameters_as_tree(:managed => true)}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    existing = %w(Element1 Element2)
    properties = create_fake_element_properties(existing, raw_property_prefix)
    properties.merge!(create_fake_element_properties(%w(Element3 Element4), raw_property_prefix))
    properties["#{raw_property_prefix}Element1.pool-name"] = 'MyDBPool'
    properties["#{raw_property_prefix}Element2.pool-name"] = 'MyDBPool'
    properties["#{raw_property_prefix}Element3.pool-name"] = 'MyOtherDBPool'
    properties["#{raw_property_prefix}Element4.pool-name"] = 'MyOtherDBPool'

    setup_interpreter_expects(executor,
                              context,
                              properties.collect{|k,v| "#{k}=#{v}"}.join("\n"))

    executor.expects(:exec).with(equals(context),
                                 equals('create-jdbc-connection-pool'),
                                 anything,
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('create-jdbc-resource'),
                                 equals(['--enabled', 'true', '--connectionpoolid', 'MyDBPool', '--description', 'Audit DB', 'jdbc/MyDB']),
                                 equals({})).
      returns('')

    existing.each do |element|
      executor.expects(:exec).with(equals(context),
                                   equals('delete-jdbc-resource'),
                                   equals([element]),
                                   equals({})).
        returns('')
    end

    perform_interpret(context, data, true, :create, :additional_task_count => 2 + existing.size, :additional_unchanged_task_count => 2)
  end

  def test_cleaner_deletes_unexpected_element
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(Element1 Element2)
    properties = create_fake_element_properties(existing, raw_property_prefix)
    properties.merge!(create_fake_element_properties(%w(Element3 Element4), raw_property_prefix))
    properties["#{raw_property_prefix}Element1.pool-name"] = 'MyDBPool'
    properties["#{raw_property_prefix}Element2.pool-name"] = 'MyDBPool'
    properties["#{raw_property_prefix}ElementX.pool-name"] = 'MyDBPool'
    properties["#{raw_property_prefix}Element3.pool-name"] = 'MyOtherDBPool'
    properties["#{raw_property_prefix}Element4.pool-name"] = 'MyOtherDBPool'
    t.context.cache_properties(properties)

    t.connectionpoolid = 'MyDBPool'
    t.expected = existing

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jdbc-resource'),
                                 equals(['ElementX']),
                                 equals({})).
      returns('')

    t.perform_action(:clean)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t, "#{raw_property_prefix}ElementX")
  end

  def test_cleaner_not_updated_if_no_clean_actions
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(Element1 Element2 Element3)
    create_fake_elements(t.context, existing)

    t.connectionpoolid = 'MyDBPool'
    t.expected = existing
    t.perform_action(:clean)

    ensure_task_not_updated_by_last_action(t)
  end

  protected

  def property_prefix
    "#{raw_property_prefix}jdbc/MyDB."
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'description' => 'Audit DB',
      'enabled' => 'true',
      'pool-name' => 'MyDBPool',
      'deployment-order' => '100'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'jdbc/MyDB',
      'enabled' => 'true',
      'connectionpoolid' => 'MyDBPool',
      'description' => 'Audit DB',
      'deployment_order' => 100
    }
  end
end
