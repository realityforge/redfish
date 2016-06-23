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

class Redfish::Tasks::Glassfish::TestJdbcConnectionPool < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_interpret_create
    data = {'jdbc_connection_pools' => resource_parameters_as_tree}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('create-jdbc-connection-pool'),
                                 equals(['--datasourceclassname=net.sourceforge.jtds.jdbcx.JtdsDataSource', '--initsql=', '--sqltracelisteners=', '--driverclassname=', '--validationclassname=', '--validationtable=', '--steadypoolsize=8', '--maxpoolsize=32', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--validateatmostonceperiod=0', '--leaktimeout=0', '--statementleaktimeout=0', '--creationretryattempts=0', '--creationretryinterval=10', '--statementtimeout=-1', '--maxconnectionusagecount=0', '--statementcachesize=0', '--isisolationguaranteed=true', '--isconnectvalidatereq=true', '--failconnection=false', '--allownoncomponentcallers=false', '--nontransactionalconnections=false', '--statementleakreclaim=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=false', '--ping=true', '--pooling=true', '--wrapjdbcobjects=true', '--restype=javax.sql.DataSource', '--isolationlevel=', '--validationmethod=auto-commit', '--property', 'Instance=MSSQLSERVER:ServerName=db\\.example\\.com:User=sa:Password=password:PortNumber=1234:DatabaseName=MYDB', '--description', 'Audit Connection Pool', 'APool']),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :create, :additional_unchanged_task_count => 1)
  end

  def test_interpret_create_when_exists
    data = {'jdbc_connection_pools' => resource_parameters_as_tree}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, to_properties_content)

    perform_interpret(context, data, false, :create, :additional_unchanged_task_count => expected_local_properties.size)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    assert_equal t.to_s, 'jdbc_connection_pool[APool]'
  end

  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(['domain.version']),
                                 equals(:terse => true, :echo => false)).
      returns("domain.version=#{DOMAIN_VERSION}\n")
    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-connection-pools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-connection-pool'),
                                 equals(['--datasourceclassname=net.sourceforge.jtds.jdbcx.JtdsDataSource', '--initsql=', '--sqltracelisteners=', '--driverclassname=', '--validationclassname=', '--validationtable=', '--steadypoolsize=8', '--maxpoolsize=32', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--validateatmostonceperiod=0', '--leaktimeout=0', '--statementleaktimeout=0', '--creationretryattempts=0', '--creationretryinterval=10', '--statementtimeout=-1', '--maxconnectionusagecount=0', '--statementcachesize=0', '--isisolationguaranteed=true', '--isconnectvalidatereq=true', '--failconnection=false', '--allownoncomponentcallers=false', '--nontransactionalconnections=false', '--statementleakreclaim=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=false', '--ping=true', '--pooling=true', '--wrapjdbcobjects=true', '--restype=javax.sql.DataSource', '--isolationlevel=', '--validationmethod=auto-commit', '--property', 'Instance=MSSQLSERVER:ServerName=db\\.example\\.com:User=sa:Password=password:PortNumber=1234:DatabaseName=MYDB', '--description', 'Audit Connection Pool', 'APool']),
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

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(['domain.version']),
                                 equals(:terse => true, :echo => false)).
      returns("domain.version=#{DOMAIN_VERSION}\n")
    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-connection-pools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("APool\n")
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

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(['domain.version']),
                                 equals(:terse => true, :echo => false)).
      returns("domain.version=#{DOMAIN_VERSION}\n")
    executor.expects(:exec).with(equals(t.context), equals('list-jdbc-connection-pools'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("APool\n")
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

    t.context.cache_properties({'domain.version' => DOMAIN_VERSION})

    t.options = resource_parameters


    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-connection-pool'),
                                 equals(['--datasourceclassname=net.sourceforge.jtds.jdbcx.JtdsDataSource', '--initsql=', '--sqltracelisteners=', '--driverclassname=', '--validationclassname=', '--validationtable=', '--steadypoolsize=8', '--maxpoolsize=32', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--validateatmostonceperiod=0', '--leaktimeout=0', '--statementleaktimeout=0', '--creationretryattempts=0', '--creationretryinterval=10', '--statementtimeout=-1', '--maxconnectionusagecount=0', '--statementcachesize=0', '--isisolationguaranteed=true', '--isconnectvalidatereq=true', '--failconnection=false', '--allownoncomponentcallers=false', '--nontransactionalconnections=false', '--statementleakreclaim=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=false', '--ping=true', '--pooling=true', '--wrapjdbcobjects=true', '--restype=javax.sql.DataSource', '--isolationlevel=', '--validationmethod=auto-commit', '--property', 'Instance=MSSQLSERVER:ServerName=db\\.example\\.com:User=sa:Password=password:PortNumber=1234:DatabaseName=MYDB', '--description', 'Audit Connection Pool', 'APool']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t)
  end

  def test_create_element_where_support_log_jdbc_calls_with_defaults
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({'domain.version' => '116'})

    t.options = resource_parameters


    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-connection-pool'),
                                 equals(['--datasourceclassname=net.sourceforge.jtds.jdbcx.JtdsDataSource', '--initsql=', '--sqltracelisteners=', '--driverclassname=', '--validationclassname=', '--validationtable=', '--steadypoolsize=8', '--maxpoolsize=32', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--validateatmostonceperiod=0', '--leaktimeout=0', '--statementleaktimeout=0', '--creationretryattempts=0', '--creationretryinterval=10', '--statementtimeout=-1', '--maxconnectionusagecount=0', '--statementcachesize=0', '--isisolationguaranteed=true', '--isconnectvalidatereq=true', '--failconnection=false', '--allownoncomponentcallers=false', '--nontransactionalconnections=false', '--statementleakreclaim=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=false', '--ping=true', '--pooling=true', '--wrapjdbcobjects=true', '--restype=javax.sql.DataSource', '--isolationlevel=', '--validationmethod=auto-commit', '--property', 'Instance=MSSQLSERVER:ServerName=db\\.example\\.com:User=sa:Password=password:PortNumber=1234:DatabaseName=MYDB', '--description', 'Audit Connection Pool', 'APool']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t,
                                 "#{property_prefix}log-jdbc-calls" => 'false',
                                 "#{property_prefix}slow-query-threshold-in-seconds" => '-1')
  end

  def test_create_element_where_support_log_jdbc_calls
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({'domain.version' => '116'})

    t.options = resource_parameters
    t.log_jdbc_calls = true
    t.slow_query_threshold_in_seconds = 33

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}log-jdbc-calls=true"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}slow-query-threshold-in-seconds=33"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jdbc-connection-pool'),
                                 equals(['--datasourceclassname=net.sourceforge.jtds.jdbcx.JtdsDataSource', '--initsql=', '--sqltracelisteners=', '--driverclassname=', '--validationclassname=', '--validationtable=', '--steadypoolsize=8', '--maxpoolsize=32', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--validateatmostonceperiod=0', '--leaktimeout=0', '--statementleaktimeout=0', '--creationretryattempts=0', '--creationretryinterval=10', '--statementtimeout=-1', '--maxconnectionusagecount=0', '--statementcachesize=0', '--isisolationguaranteed=true', '--isconnectvalidatereq=true', '--failconnection=false', '--allownoncomponentcallers=false', '--nontransactionalconnections=false', '--statementleakreclaim=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=false', '--ping=true', '--pooling=true', '--wrapjdbcobjects=true', '--restype=javax.sql.DataSource', '--isolationlevel=', '--validationmethod=auto-commit', '--property', 'Instance=MSSQLSERVER:ServerName=db\\.example\\.com:User=sa:Password=password:PortNumber=1234:DatabaseName=MYDB', '--description', 'Audit Connection Pool', 'APool']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t,
                                 "#{property_prefix}log-jdbc-calls" => 'true',
                                 "#{property_prefix}slow-query-threshold-in-seconds" => '33')
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

    t.context.cache_properties(cache_values.merge('domain.version' => DOMAIN_VERSION))

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

    t.context.cache_properties(expected_properties.merge('domain.version' => DOMAIN_VERSION))

    t.options = resource_parameters

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)

    ensure_expected_cache_values(t)
  end

  def test_delete_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'APool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jdbc-connection-pools'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'APool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-jdbc-connection-pools'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("APool\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jdbc-connection-pool'),
                                 equals(['--cascade=true', 'APool']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties('domain.version' => DOMAIN_VERSION)
    t.options = {'name' => 'APool'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties.merge('domain.version' => DOMAIN_VERSION))
    t.options = {'name' => 'APool'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jdbc-connection-pool'),
                                 equals(%w(--cascade=true APool)),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_interpret_create_and_delete
    data = {'jdbc_connection_pools' => resource_parameters_as_tree(:managed => true)}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    existing = %w(Element1 Element2)
    setup_interpreter_expects_with_fake_elements(executor, context, existing)

    executor.expects(:exec).with(equals(context),
                                 equals('create-jdbc-connection-pool'),
                                 equals(['--datasourceclassname=net.sourceforge.jtds.jdbcx.JtdsDataSource', '--initsql=', '--sqltracelisteners=', '--driverclassname=', '--validationclassname=', '--validationtable=', '--steadypoolsize=8', '--maxpoolsize=32', '--maxwait=60000', '--poolresize=2', '--idletimeout=300', '--validateatmostonceperiod=0', '--leaktimeout=0', '--statementleaktimeout=0', '--creationretryattempts=0', '--creationretryinterval=10', '--statementtimeout=-1', '--maxconnectionusagecount=0', '--statementcachesize=0', '--isisolationguaranteed=true', '--isconnectvalidatereq=true', '--failconnection=false', '--allownoncomponentcallers=false', '--nontransactionalconnections=false', '--statementleakreclaim=false', '--leakreclaim=false', '--lazyconnectionenlistment=false', '--lazyconnectionassociation=false', '--associatewiththread=false', '--matchconnections=false', '--ping=true', '--pooling=true', '--wrapjdbcobjects=true', '--restype=javax.sql.DataSource', '--isolationlevel=', '--validationmethod=auto-commit', '--property', 'Instance=MSSQLSERVER:ServerName=db\\.example\\.com:User=sa:Password=password:PortNumber=1234:DatabaseName=MYDB', '--description', 'Audit Connection Pool', 'APool']),
                                 equals({})).
      returns('')

    existing.each do |element|
      executor.expects(:exec).with(equals(context),
                                   equals('delete-jdbc-connection-pool'),
                                   equals(%W(--cascade=true #{element})),
                                   equals({})).
        returns('')
    end

    perform_interpret(context,
                      data,
                      true,
                      :create,
                      :additional_task_count => 1 + existing.size,
                      # clean actions for each pool deleted
                      :additional_unchanged_task_count => 1 + existing.size)
  end

  def test_cleaner_deletes_unexpected_element
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(Element1 Element2 Element3)
    create_fake_elements(t.context, existing)

    t.context.property_cache["#{Redfish::Tasks::Glassfish::JdbcResource::PROPERTY_PREFIX}SubElement1.pool-name"] = 'Element1'
    t.context.property_cache["#{Redfish::Tasks::Glassfish::JdbcResource::PROPERTY_PREFIX}SubElement2.pool-name"] = 'Element2'
    t.context.property_cache["#{Redfish::Tasks::Glassfish::JdbcResource::PROPERTY_PREFIX}SubElement3.pool-name"] = 'Element3'

    t.expected = existing[1, existing.size]

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jdbc-connection-pool'),
                                 equals(%W(--cascade=true #{existing.first})),
                                 equals({})).
      returns('')

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jdbc-resource'),
                                 equals(['SubElement1']),
                                 equals({})).
      returns('')

    t.perform_action(:clean)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t, "#{raw_property_prefix}#{existing.first}")
  end

  def test_cleaner_not_updated_if_no_clean_actions
    executor = Redfish::Executor.new
    t = new_cleaner_task(executor)

    existing = %w(Element1 Element2 Element3)
    create_fake_elements(t.context, existing)

    t.expected = existing
    t.perform_action(:clean)

    ensure_task_not_updated_by_last_action(t)
  end

  protected

  def property_prefix
    "#{raw_property_prefix}APool."
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'description' => 'Audit Connection Pool',
      'datasource-classname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
      'init-sql' => '',
      'sql-trace-listeners' => '',
      'driver-classname' => '',
      'validation-classname' => '',
      'validation-table-name' => '',
      'steady-pool-size' => '8',
      'max-pool-size' => '32',
      'max-wait-time-in-millis' => '60000',
      'pool-resize-quantity' => '2',
      'idle-timeout-in-seconds' => '300',
      'validate-atmost-once-period-in-seconds' => '0',
      'connection-leak-timeout-in-seconds' => '0',
      'statement-leak-timeout-in-seconds' => '0',
      'connection-creation-retry-attempts' => '0',
      'connection-creation-retry-interval-in-seconds' => '10',
      'statement-timeout-in-seconds' => '-1',
      'max-connection-usage-count' => '0',
      'statement-cache-size' => '0',
      'is-isolation-level-guaranteed' => 'true',
      'is-connection-validation-required' => 'true',
      'fail-all-connections' => 'false',
      'allow-non-component-callers' => 'false',
      'non-transactional-connections' => 'false',
      'statement-leak-reclaim' => 'false',
      'connection-leak-reclaim' => 'false',
      'lazy-connection-enlistment' => 'false',
      'lazy-connection-association' => 'false',
      'associate-with-thread' => 'false',
      'match-connections' => 'false',
      'ping' => 'true',
      'pooling' => 'true',
      'wrap-jdbc-objects' => 'true',
      'res-type' => 'javax.sql.DataSource',
      'transaction-isolation-level' => '',
      'connection-validation-method' => 'auto-commit',
      'property.Instance' => 'MSSQLSERVER',
      'property.ServerName' => 'db.example.com',
      'property.User' => 'sa',
      'property.Password' => 'password',
      'property.PortNumber' => '1234',
      'property.DatabaseName' => 'MYDB',
      'deployment-order' => '100'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'APool',
      'datasourceclassname' => 'net.sourceforge.jtds.jdbcx.JtdsDataSource',
      'restype' => 'javax.sql.DataSource',
      'validationmethod' => 'auto-commit',
      'isconnectvalidatereq' => 'true',
      'ping' => 'true',
      'description' => 'Audit Connection Pool',
      'deployment_order' => 100,
      'properties' =>
        {
          'Instance' => 'MSSQLSERVER',
          'ServerName' => 'db.example.com',
          'User' => 'sa',
          'Password' => 'password',
          'PortNumber' => '1234',
          'DatabaseName' => 'MYDB'
        }
    }
  end

  def reference_properties
    {}
  end
end
