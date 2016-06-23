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

class Redfish::Tasks::Glassfish::TestConnectorConnectionPool < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_interpret_create
    data = {'resource_adapters' => {'jmsra' => {'connection_pools' => resource_parameters_as_tree}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('create-resource-adapter-config'),
                                 anything,
                                 equals({})).
      returns('')

    executor.expects(:exec).with(equals(context),
                                 equals('create-connector-connection-pool'),
                                 equals(['--raname=jmsra', '--connectiondefinition=javax.jms.QueueConnectionFactory', '--steadypoolsize=1', '--maxpoolsize=250', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--leaktimeout=0', '--validateatmostonceperiod=0', '--maxconnectionusagecount=0', '--creationretryattempts=0', '--creationretryinterval=10', '--isconnectvalidatereq=true', '--failconnection=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=true', '--ping=true', '--pooling=true', '--transactionsupport=NoTransaction', '--property', 'User=sa:Password=password', '--description', 'Audit Connection Pool', 'MyConnectorConnectionPool']),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :create, :additional_task_count => 1, :additional_unchanged_task_count => 1)
  end

  def test_interpret_create_when_exists
    data = {'resource_adapters' => {'jmsra' => {'connection_pools' => resource_parameters_as_tree}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, to_properties_content)

    executor.expects(:exec).with(equals(context),
                                 equals('create-resource-adapter-config'),
                                 anything,
                                 equals({})).
      returns('')

    perform_interpret(context, data, false, :create, :additional_task_count => 1, :additional_unchanged_task_count => expected_local_properties.size)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    assert_equal t.to_s, 'connector_connection_pool[MyConnectorConnectionPool::jmsra]'
  end

  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-connector-connection-pools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-connector-connection-pool'),
                                 equals(['--raname=jmsra', '--connectiondefinition=javax.jms.QueueConnectionFactory', '--steadypoolsize=1', '--maxpoolsize=250', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--leaktimeout=0', '--validateatmostonceperiod=0', '--maxconnectionusagecount=0', '--creationretryattempts=0', '--creationretryinterval=10', '--isconnectvalidatereq=true', '--failconnection=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=true', '--ping=true', '--pooling=true', '--transactionsupport=NoTransaction', '--property', 'User=sa:Password=password', '--description', 'Audit Connection Pool', 'MyConnectorConnectionPool']),
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

    executor.expects(:exec).with(equals(t.context), equals('list-connector-connection-pools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyConnectorConnectionPool\n")
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

    executor.expects(:exec).with(equals(t.context), equals('list-connector-connection-pools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyConnectorConnectionPool\n")
    # Return a property that should be deleted
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.DatabaseName2=MYDB\n")

    cache_values = expected_local_properties
    cache_values['description'] = 'X'
    cache_values['ping'] = 'false'
    cache_values['deployment-order'] = '99'
    cache_values['property.Password'] = 'secret'
    cache_values['property.DatabaseName2'] = 'MYDB'

    cache_values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.Password=password"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}deployment-order=100"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}description=Audit Connection Pool"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}ping=true"]),
                                 equals(:terse => true, :echo => false))

    # This is the set to remove property that should not exist
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.DatabaseName2="]),
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
                                 equals('create-connector-connection-pool'),
                                 equals(['--raname=jmsra', '--connectiondefinition=javax.jms.QueueConnectionFactory', '--steadypoolsize=1', '--maxpoolsize=250', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--leaktimeout=0', '--validateatmostonceperiod=0', '--maxconnectionusagecount=0', '--creationretryattempts=0', '--creationretryinterval=10', '--isconnectvalidatereq=true', '--failconnection=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=true', '--ping=true', '--pooling=true', '--transactionsupport=NoTransaction', '--property', 'User=sa:Password=password', '--description', 'Audit Connection Pool', 'MyConnectorConnectionPool']),
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

    cache_values["#{property_prefix}ping"] = 'false'
    cache_values["#{property_prefix}description"] = 'XXX'
    cache_values["#{property_prefix}deployment-order"] = '101'
    cache_values["#{property_prefix}property.Password"] = 'secret'

    # This property should be removed
    cache_values["#{property_prefix}property.DatabaseName2"] = 'MYDB'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters


    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.Password=password"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}deployment-order=100"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}description=Audit Connection Pool"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}ping=true"]),
                                 equals(:terse => true, :echo => false))

    # This is the set to remove property that should not exist
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.DatabaseName2="]),
                                 equals(:terse => true, :echo => false)).
      returns('')

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

    t.options = {'name' => 'MyConnectorConnectionPool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-connector-connection-pools'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'MyConnectorConnectionPool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-connector-connection-pools'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("MyConnectorConnectionPool\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-connector-connection-pool'),
                                 equals(['--cascade=true', 'MyConnectorConnectionPool']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'MyConnectorConnectionPool'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'MyConnectorConnectionPool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-connector-connection-pool'),
                                 equals(['--cascade=true', 'MyConnectorConnectionPool']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_interpret_create_and_delete
    data = {'resource_adapters' => {'jmsra' => {'connection_pools' => resource_parameters_as_tree(:managed => true)}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    existing = %w(Element1 Element2)
    properties = create_fake_element_properties(existing, raw_property_prefix)
    properties.merge!(create_fake_element_properties(%w(Element3 Element4), raw_property_prefix))
    properties["#{raw_property_prefix}Element1.resource-adapter-name"] = 'jmsra'
    properties["#{raw_property_prefix}Element2.resource-adapter-name"] = 'jmsra'
    properties["#{raw_property_prefix}Element3.resource-adapter-name"] = 'MyOtherDBPool'
    properties["#{raw_property_prefix}Element4.resource-adapter-name"] = 'MyOtherDBPool'

    setup_interpreter_expects(executor,
                              context,
                              properties.collect{|k,v| "#{k}=#{v}"}.join("\n"))

    executor.expects(:exec).with(equals(context),
                                 equals('create-resource-adapter-config'),
                                 anything,
                                 equals({})).
      returns('')

    executor.expects(:exec).with(equals(context),
                                 equals('create-connector-connection-pool'),
                                 equals(['--raname=jmsra', '--connectiondefinition=javax.jms.QueueConnectionFactory', '--steadypoolsize=1', '--maxpoolsize=250', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--leaktimeout=0', '--validateatmostonceperiod=0', '--maxconnectionusagecount=0', '--creationretryattempts=0', '--creationretryinterval=10', '--isconnectvalidatereq=true', '--failconnection=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=true', '--ping=true', '--pooling=true', '--transactionsupport=NoTransaction', '--property', 'User=sa:Password=password', '--description', 'Audit Connection Pool', 'MyConnectorConnectionPool']),
                                 equals({})).
      returns('')

    existing.each do |element|
      executor.expects(:exec).with(equals(context),
                                   equals('delete-connector-connection-pool'),
                                   equals(%W(--cascade=true #{element})),
                                   equals({})).
        returns('')
    end

    perform_interpret(context,
                      data,
                      true,
                      :create,
                      # existing results in a delete
                      :additional_task_count => 2 + existing.size,
                      # clean action for every pool deleted
                      :additional_unchanged_task_count => 1 + existing.size)
  end

  def test_cleaner_deletes_unexpected_element
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(Element1 Element2)
    properties = create_fake_element_properties(existing, raw_property_prefix)
    properties.merge!(create_fake_element_properties(%w(Element3 Element4), raw_property_prefix))
    properties["#{raw_property_prefix}Element1.resource-adapter-name"] = 'jmsra'
    properties["#{raw_property_prefix}Element2.resource-adapter-name"] = 'jmsra'
    properties["#{raw_property_prefix}ElementX.resource-adapter-name"] = 'jmsra'
    properties["#{raw_property_prefix}Element3.resource-adapter-name"] = 'MyOtherDBPool'
    properties["#{raw_property_prefix}Element4.resource-adapter-name"] = 'MyOtherDBPool'
    t.context.cache_properties(properties)

    t.context.property_cache["#{Redfish::Tasks::Glassfish::ConnectorResource::PROPERTY_PREFIX}SubElement1.pool-name"] = 'Element1'
    t.context.property_cache["#{Redfish::Tasks::Glassfish::ConnectorResource::PROPERTY_PREFIX}SubElement2.pool-name"] = 'Element2'
    t.context.property_cache["#{Redfish::Tasks::Glassfish::ConnectorResource::PROPERTY_PREFIX}SubElement3.pool-name"] = 'ElementX'
    t.context.property_cache["#{Redfish::Tasks::Glassfish::ConnectorResource::PROPERTY_PREFIX}SubElement4.pool-name"] = 'Element3'
    t.context.property_cache["#{Redfish::Tasks::Glassfish::ConnectorResource::PROPERTY_PREFIX}SubElement5.pool-name"] = 'Element4'

    t.resource_adapter_name = 'jmsra'
    t.expected = existing

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-connector-connection-pool'),
                                 equals(%W(--cascade=true ElementX)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-connector-resource'),
                                 equals(['SubElement3']),
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

    t.resource_adapter_name = 'jmsra'
    t.expected = existing
    t.perform_action(:clean)

    ensure_task_not_updated_by_last_action(t)
  end

  protected

  def property_prefix
    "#{raw_property_prefix}MyConnectorConnectionPool."
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'connection-definition-name' => 'javax.jms.QueueConnectionFactory',
      'resource-adapter-name' => 'jmsra',
      'transaction-support' => 'NoTransaction',
      'description' => 'Audit Connection Pool',
      'steady-pool-size' => '1',
      'max-pool-size' => '250',
      'max-wait-time-in-millis' => '60000',
      'pool-resize-quantity' => '2',
      'idle-timeout-in-seconds' => '300',
      'validate-atmost-once-period-in-seconds' => '0',
      'connection-leak-timeout-in-seconds' => '0',
      'connection-creation-retry-attempts' => '0',
      'connection-creation-retry-interval-in-seconds' => '10',
      'max-connection-usage-count' => '0',
      'is-connection-validation-required' => 'true',
      'fail-all-connections' => 'false',
      'connection-leak-reclaim' => 'false',
      'lazy-connection-enlistment' => 'false',
      'lazy-connection-association' => 'false',
      'associate-with-thread' => 'false',
      'match-connections' => 'true',
      'ping' => 'true',
      'deployment-order' => '100',
      'pooling' => 'true',
      'property.User' => 'sa',
      'property.Password' => 'password'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'MyConnectorConnectionPool',
      'resource_adapter_name' => 'jmsra',
      'connection_definition_name' => 'javax.jms.QueueConnectionFactory',
      'transaction_support' => 'NoTransaction',
      'description' => 'Audit Connection Pool',
      'is_connection_validation_required' => 'true',
      'ping' => 'true',
      'deployment_order' => 100,
      'properties' =>
        {
          'User' => 'sa',
          'Password' => 'password'
        }
    }
  end

  def reference_properties
    {}
  end
end
