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

class Redfish::Tasks::BaseTaskTest < Redfish::TestCase

  protected

  def ensure_task_updated_by_last_action(task)
    assert_equal task.updated_by_last_action?, true, 'Expected to update with last action'
  end

  def ensure_task_not_updated_by_last_action(task)
    assert_equal task.updated_by_last_action?, false, 'Expected to not update with last action'
  end

  def ensure_properties_not_present(task)
    assert_equal task.context.property_cache.any_property_start_with?(property_prefix), false
  end

  def ensure_expected_cache_values(t)
    expected_properties.each_pair do |key, value|
      assert_equal t.context.property_cache[key], value, "Expected #{key}=#{value}"
    end
  end

  def property_prefix
    raise 'property_prefix not overridden'
  end

  def expected_properties
    cache_values = {}

    expected_local_properties.each_pair do |k, v|
      cache_values["#{property_prefix}#{k}"] = "#{v}"
    end
    cache_values
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    raise 'expected_local_properties not overridden'
  end

  # Resource parameters
  def resource_parameters
    raise 'resource_parameters not overridden'
  end

  def new_task(executor = Redfish::Executor.new)
    t = Redfish::Tasks.const_get(task_name).new
    t.context = create_simple_context(executor)
    t
  end

  def task_name
    self.class.name.to_s.split('::').last.gsub(/^Test/,'')
  end

  def registered_name
    Redfish::Naming.underscore(task_name)
  end

  def perform_interpret(context, data, task_ran, expected_task_action, options = {})
    run_context = interpret(context, data)

    updated_records = to_updated_resource_records(run_context)
    unchanged_records = to_unchanged_resource_records(run_context)

    assert_equal updated_records.size, (task_ran ? 1 : 0) + 2 + (options[:additional_task_count].nil? ? 0 : options[:additional_task_count])
    assert_equal unchanged_records.size, (task_ran ? 0 : 1) + (options[:exclude_jvm_options].nil? ? 1 : 0)

    assert_property_cache_records(updated_records)

    record_under_test = get_record_under_test(task_ran ? updated_records : unchanged_records, expected_task_action)
    ensure_task_record(record_under_test, task_ran, false)
    record_under_test
  end

  def resource_parameters_as_tree(name_key = 'name')
    params = resource_parameters
    name = params.delete(name_key)
    assert_not_nil name
    {name => params}
  end

  def to_properties_content
    properties = nil
    expected_local_properties.each_pair do |k, v|
      properties = (properties.nil? ? '' : "#{properties}\n") + "#{property_prefix}#{k}=#{v}"
    end
    properties
  end

  def setup_interpreter_expects(executor, context, property_results)
    mock_property_get(executor,
                      context,
                      "domain.version=270\nconfigs.config.server-config.java-config.jvm-options=-DANTLR_USE_DIRECT_CLASS_LOADING=true,-Dcom.sun.enterprise.config.config_environment_factory_class=com.sun.enterprise.config.serverbeans.AppserverConfigEnvironmentFactory,-Dcom.sun.enterprise.security.httpsOutboundKeyAlias=s1as,-Djava.awt.headless=true,-Djava.endorsed.dirs=${com.sun.aas.installRoot}/modules/endorsed${path.separator}${com.sun.aas.installRoot}/lib/endorsed,-Djava.ext.dirs=${com.sun.aas.javaRoot}/lib/ext${path.separator}${com.sun.aas.javaRoot}/jre/lib/ext${path.separator}${com.sun.aas.instanceRoot}/lib/ext,-Djava.security.auth.login.config=${com.sun.aas.instanceRoot}/config/login.conf,-Djava.security.policy=${com.sun.aas.instanceRoot}/config/server.policy,-Djavax.net.ssl.keyStore=${com.sun.aas.instanceRoot}/config/keystore.jks,-Djavax.net.ssl.trustStore=${com.sun.aas.instanceRoot}/config/cacerts.jks,-Djdbc.drivers=org.apache.derby.jdbc.ClientDriver,-Djdk.corba.allowOutputStreamSubclass=true,-Djdk.tls.rejectClientInitiatedRenegotiation=true,-Dorg.jboss.weld.serialization.beanIdentifierIndexOptimization=false\n#{property_results}")
  end

  def mock_property_get(executor, context, results)
    executor.
      expects(:exec).
      with(equals(context), equals('get'), equals(%w(*)), equals(:terse => true, :echo => false)).
      returns(results)
  end

  def assert_property_cache_records(records)
    assert_equal records.select { |r| r.task.class.registered_name == 'property_cache' && r.action == :create }.size, 1
    assert_equal records.select { |r| r.task.class.registered_name == 'property_cache' && r.action == :destroy }.size, 1
  end

  def ensure_task_record(record, updated, errored)
    assert_equal record.action_error?, errored
    assert record.action_started?
    assert record.action_finished?
    assert_equal record.action_performed_update?, updated
  end

  def get_record_under_test(records, action_name)
    records_under_test = records.select { |r| r.task.class.registered_name == registered_name && r.action == action_name }
    assert_equal records_under_test.size, 1
    records_under_test[0]
  end

  def interpret(context, data)
    run_context = Redfish::RunContext.new(context)
    Redfish::Interpreter.interpret(run_context, data)
    run_context.converge
    run_context
  end

  def to_unchanged_resource_records(context)
    context.execution_records.select { |action_record| !action_record.action_performed_update? }
  end

  def to_updated_resource_records(context)
    context.execution_records.select { |action_record| action_record.action_performed_update? }
  end
end
