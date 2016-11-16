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

class Redfish::Tasks::Glassfish::TestJmsResource < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_interpret_create
    data = {'jms_resources' => resource_parameters_as_tree}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('create-resource-adapter-config'),
                                 anything,
                                 equals({})).
      returns('')

    executor.expects(:exec).with(equals(context),
                                 equals('create-admin-object'),
                                 equals(['--enabled', 'true', '--raname', 'jmsra', '--restype', 'javax.jms.Queue', '--property', 'Name=MyPhysicalJmsResource', '--description', 'Blah blee', '--classname', 'com.sun.messaging.Queue', 'MyJmsResource']),
                                 equals({})).
      returns('')

    perform_interpret(context,
                      data,
                      true,
                      :create,
                      :additional_task_count => 1,
                      :additional_unchanged_task_count => 11,
                      :exclude_record_under_test => true)
  end

  def test_interpret_create_when_exists
    data = {'jms_resources' => resource_parameters_as_tree}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, to_properties_content)

    executor.expects(:exec).with(equals(context),
                                 equals('create-resource-adapter-config'),
                                 anything,
                                 equals({})).
      returns('')

    perform_interpret(context,
                      data,
                      false,
                      :create,
                      :additional_unchanged_task_count => 10 + expected_local_properties.size,
                      :additional_task_count => 1)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    assert_equal t.to_s, 'jms_resource[MyJmsResource]'
  end

  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-jms-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jms-resource'),
                                 equals(['--enabled', 'true', '--restype', 'javax.jms.Queue', '--property', 'Name=MyPhysicalJmsResource', '--description', 'Blah blee', 'MyJmsResource']),
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

    executor.expects(:exec).with(equals(t.context), equals('list-jms-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyJmsResource\n")
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

    executor.expects(:exec).with(equals(t.context), equals('list-jms-resources'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyJmsResource\n")
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
                                 equals('create-jms-resource'),
                                 equals(['--enabled', 'true', '--restype', 'javax.jms.Queue', '--property', 'Name=MyPhysicalJmsResource', '--description', 'Blah blee', 'MyJmsResource']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t)
  end

  def test_create_connection_factory_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    t.options = {'name' => 'MyConnectionFactory',
                 'restype' => 'javax.jms.ConnectionFactory',
                 'properties' => {'UserName' => 'bob', 'transaction_support' => 'LocalTransaction'},
                 'description' => 'Blah blee'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jms-resource'),
                                 equals(['--enabled', 'true', '--restype', 'javax.jms.ConnectionFactory', '--property', 'UserName=bob', '--description', 'Blah blee', 'MyConnectionFactory']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    assert_cached_property(t, 'resources.connector-resource.MyConnectionFactory.description', 'Blah blee')
    assert_cached_property(t, 'resources.connector-resource.MyConnectionFactory.enabled', 'true')
    assert_cached_property(t, 'resources.connector-resource.MyConnectionFactory.property.UserName', 'bob')
    # transaction_support should not be passed through and instead is processed by pre_interpreter to
    # copy them as connector pool properties
    assert_cached_property(t, 'resources.connector-resource.MyConnectionFactory.property.transaction_support', nil)
    assert_cached_property(t, 'resources.connector-resource.MyConnectionFactory.deployment-order', '100')
    assert_cached_property(t, 'resources.connector-resource.MyConnectionFactory.object-type', 'user')
    assert_cached_property(t, 'resources.connector-resource.MyConnectionFactory.jndi-name', 'MyConnectionFactory')
    assert_cached_property(t, 'servers.server.server.resource-ref.MyConnectionFactory.ref', 'MyConnectionFactory')
    assert_cached_property(t, 'servers.server.server.resource-ref.MyConnectionFactory.enabled', 'true')
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
                                 equals(["#{property_prefix}description=Blah blee"]),
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

    t.options = {'name' => 'MyJmsResource'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jms-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('').
      at_least(2)

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'MyJmsResource'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jms-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("MyJmsResource\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jms-resources'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jms-resource'),
                                 equals(['MyJmsResource']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'MyJmsResource'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'MyJmsResource'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jms-resource'),
                                 equals(['MyJmsResource']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present_and_element_deletion_is_restricted
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties.merge!("#{property_prefix}object-type" => 'system-all-req'))
    t.options = {'name' => 'MyJmsResource'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(['resources.admin-object-resource.MyJmsResource.object-type=system-all']),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jms-resource'),
                                 equals(['MyJmsResource']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  protected

  def property_prefix
    'resources.admin-object-resource.MyJmsResource.'
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'description' => 'Blah blee',
      'enabled' => 'true',
      'res-type' => 'javax.jms.Queue',
      'res-adapter' => 'jmsra',
      'property.Name' => 'MyPhysicalJmsResource',
      'deployment-order' => '100',
      'class-name' => 'com.sun.messaging.Queue'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'MyJmsResource',
      'restype' => 'javax.jms.Queue',
      'enabled' => 'true',
      'description' => 'Blah blee',
      'properties' => {'Name' => 'MyPhysicalJmsResource'},
      'deployment_order' => 100
    }
  end
end
