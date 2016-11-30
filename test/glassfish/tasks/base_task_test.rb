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

class Redfish::Tasks::Glassfish::BaseTaskTest < Redfish::TestCase

  DOMAIN_CONTEXT_ONLY_RESTART_IF_REQUIRED_ACTIONS = 3
  DOMAIN_RESTART_IF_REQUIRED_ACTIONS = 7 + DOMAIN_CONTEXT_ONLY_RESTART_IF_REQUIRED_ACTIONS

  DEFAULT_VERSION=Redfish::Versions::Payara154.new

  JVM_OPTIONS_HASH = DEFAULT_VERSION.default_jvm_defines
  JVM_OPTIONS_OUTPUT = JVM_OPTIONS_HASH.collect { |k, v| "-D#{k}=#{v}" }.join("\n")
  JVM_OPTIONS = JVM_OPTIONS_HASH.collect { |k, v| "-D#{k}=#{v}" }.join(';')
  DOMAIN_VERSION = '270'

  protected

  def ensure_task_updated_by_last_action(task)
    assert_equal task.updated_by_last_action?, true, 'Expected to update with last action'
  end

  def ensure_task_not_updated_by_last_action(task)
    assert_equal task.updated_by_last_action?, false, 'Expected to not update with last action'
  end

  def ensure_properties_not_present(task, prefix = property_prefix)
    assert_equal task.context.property_cache.any_property_start_with?(prefix), false, "Properties with prefix #{prefix} are present when not expected"
  end

  def ensure_expected_cache_values(t, options = {})
    expected_properties.merge(options).each_pair do |key, value|
      assert_cached_property(t, key, value)
    end
  end

  def assert_cached_property(t, key, value)
    assert_equal t.context.property_cache[key], value, "Expected #{key}=#{value}"
  end

  def property_prefix
    raise 'property_prefix not overridden'
  end

  def reference_properties
    name = self.resource_name
    {
      "servers.server.server.resource-ref.#{name}.enabled" => 'true',
      "servers.server.server.resource-ref.#{name}.ref" => name
    }
  end

  def resource_name
    resource_parameters['name']
  end

  def expected_properties
    cache_values = {}

    expected_local_properties.each_pair do |k, v|
      cache_values["#{property_prefix}#{k}"] = "#{v}"
    end
    cache_values.merge!(reference_properties)
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

  def new_task(executor = Redfish::Executor.new, task_suffix = '')
    new_task_with_context(create_simple_context(executor), task_suffix)
  end

  def new_task_with_context(context, task_suffix = '')
    t = task_class(task_suffix).new
    t.run_context = Redfish::RunContext.new(context)
    t
  end

  def new_cleaner_task(executor)
    new_task(executor, 'Cleaner')
  end

  def task_class(task_suffix)
    Redfish::Tasks::Glassfish.const_get("#{task_name}#{task_suffix}")
  end

  def task_name
    self.class.name.to_s.split('::').last.gsub(/^Test/, '')
  end

  def registered_name
    Reality::Naming.underscore(task_name)
  end

  def perform_interpret(context, data, task_ran, expected_task_action, options = {})
    add_excludes_unless_defined = options[:add_excludes_unless_defined].nil? ? true : options[:add_excludes_unless_defined]
    data = data.dup

    data['config'] = {}
    data['config']['diff_on_completion'] = false

    data['jvm_options']['managed'] = true
    Redfish::Interpreter::PreInterpreter.mark_as_unmanaged(data) if add_excludes_unless_defined

    exclude_domain_create = options[:exclude_domain_create].nil? ? false : !!options[:exclude_domain_create]
    domain_dir_exists = options[:domain_dir_exists].nil? ? false : !!options[:domain_dir_exists]

    executor = context.instance_variable_get('@executor')
    unless exclude_domain_create
      unless domain_dir_exists
        executor.expects(:exec).
          with(equals(context),
               equals('create-domain'),
               equals(%W(--checkports=false --savelogin=false --savemasterpassword=true --nopassword=true --usemasterpassword=true --domaindir #{test_domains_dir} --domainproperties domain.adminPort=4848 domain1)),
               has_key(:domain_password_file)).
          returns('')
      end
      executor.expects(:exec).
        with(equals(context),
             equals('list-domains'),
             equals(%W(--domaindir #{test_domains_dir})),
             equals({:terse => true, :echo => false})).
        returns('')
      executor.expects(:exec).
        with(equals(context),
             equals('start-domain'),
             equals(%W(--domaindir #{test_domains_dir} domain1)),
             equals({})).
        returns('')
      executor.expects(:exec).
        with(equals(context),
             equals('_get-restart-required'),
             equals([]),
             equals({:terse => true, :echo => false})).
        returns("false\n").
        at_least(DOMAIN_RESTART_IF_REQUIRED_ACTIONS - DOMAIN_CONTEXT_ONLY_RESTART_IF_REQUIRED_ACTIONS)
    end

    include_jvm_options = options[:exclude_jvm_options].nil?
    if include_jvm_options
      executor.expects(:exec).
        with(equals(context),
             equals('list-jvm-options'),
             equals([]),
             equals({:terse => true, :echo => false})).
        returns(JVM_OPTIONS_OUTPUT)
    end

    run_context = interpret(context, data)

    updated_records = to_updated_resource_records(run_context)
    unchanged_records = to_unchanged_resource_records(run_context)

    domain_create_count = exclude_domain_create ? 0 : (domain_dir_exists ? 2 : 3)
    domain_restart_check = exclude_domain_create ? 0 : DOMAIN_RESTART_IF_REQUIRED_ACTIONS

    additional_task_count = options[:additional_task_count].nil? ? 0 : options[:additional_task_count]
    additional_unchanged_task_count = options[:additional_unchanged_task_count].nil? ? 0 : options[:additional_unchanged_task_count]

    jvm_options_task_count = (include_jvm_options ? 1 : 0)

    complete_task_count = 1

    property_cache_reload_updates = !!options[:property_cache_reload_updates]

    property_cache_actions = 2 + (property_cache_reload_updates ? 1 : 0)
    property_cache_reload = (property_cache_reload_updates ? 0 : 1)

    expected_updated = domain_create_count + (task_ran ? 1 : 0) + property_cache_actions + additional_task_count
    assert_equal updated_records.size, expected_updated, "Expected Updated Count #{expected_updated} - Actual:\n#{updated_records.collect { |a| a.to_s }.join("\n")}"

    expected_unchanged = (task_ran ? 0 : 1) + property_cache_reload + (domain_dir_exists ? 1 : 0) + additional_unchanged_task_count + domain_restart_check + jvm_options_task_count + complete_task_count
    assert_equal unchanged_records.size, expected_unchanged, "Expected Unchanged Count #{expected_unchanged} - Actual:\n#{unchanged_records.collect { |a| a.to_s }.join("\n")}"

    assert_property_cache_records(updated_records, property_cache_reload_updates)

    unless exclude_domain_create
      assert_equal updated_records.select { |r| r.task.class.registered_name == 'domain' && r.action == :create }.size, 1, 'updated domain.create actions' unless domain_dir_exists
      assert_equal updated_records.select { |r| r.task.class.registered_name == 'domain' && r.action == :start }.size, 1, 'updated domain.start actions'
      assert_equal updated_records.select { |r| r.task.class.registered_name == 'domain' && r.action == :ensure_active }.size, 1, 'updated domain.ensure_active actions'
      assert_equal unchanged_records.select { |r| r.task.class.registered_name == 'domain' && r.action == :restart_if_required }.size, DOMAIN_RESTART_IF_REQUIRED_ACTIONS, 'unchanged domain.restart_if_required actions'
      assert_equal unchanged_records.select { |r| r.task.class.registered_name == 'domain' && r.action == :complete }.size, 1, 'unchanged domain.complete actions'
    end

    return nil if options[:exclude_record_under_test]

    record_under_test = get_record_under_test(task_ran ? updated_records : unchanged_records, expected_task_action)
    ensure_task_record(record_under_test, task_ran, false)
    record_under_test
  end

  def resource_parameters_as_tree(options = {})
    name_key = options[:name_key] || 'name'
    managed = options[:managed]
    params = resource_parameters
    name = params.delete(name_key)
    assert_not_nil name
    results = {name => params}
    results['managed'] = managed unless managed.nil?
    results
  end

  def to_properties_content
    properties = nil
    expected_local_properties.each_pair do |k, v|
      properties = (properties.nil? ? '' : "#{properties}\n") + "#{property_prefix}#{k}=#{v}"
    end
    properties
  end

  def setup_interpreter_expects_with_fake_elements(executor, context, names, property_prefix = raw_property_prefix, attributes = %w(p q r s t u v))
    setup_interpreter_expects(executor, context, create_fake_element_properties(names, property_prefix, attributes).collect { |k, v| "#{k}=#{v}" }.join("\n"))
  end

  def setup_interpreter_expects(executor, context, property_results, count = 2)
    data = "domain.version=#{DOMAIN_VERSION}\nconfigs.config.server-config.java-config.jvm-options=#{JVM_OPTIONS}\n#{property_results}"
    mock_property_get(executor, context, data, count)
  end

  def mock_property_get(executor, context, results, times = 1)
    executor.
      expects(:exec).
      with(equals(context), equals('get'), equals(%w(*)), equals(:terse => true, :echo => false)).
      times(times).
      returns(results)
  end

  def assert_property_cache_records(records, property_cache_reload_updates)
    assert_equal records.select { |r| r.task.class.registered_name == 'property_cache' && r.action == :create }.size, 1 + (property_cache_reload_updates ? 1 : 0)
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
    run_context.execution_records.each do |execution_record|
      if execution_record.task.is_a?(Redfish::Tasks::Glassfish::Domain)
        execution_record.task.stubs(:do_ensure_active)
      end
    end
    run_context.converge
    run_context
  end

  def to_unchanged_resource_records(context)
    context.execution_records.select { |action_record| !action_record.action_performed_update? }
  end

  def to_updated_resource_records(context)
    context.execution_records.select { |action_record| action_record.action_performed_update? }
  end

  def raw_property_prefix
    Redfish::Tasks.const_get(task_name).const_get(:PROPERTY_PREFIX)
  end

  def create_fake_elements(context, names, property_prefix = raw_property_prefix, attributes = %w(p q r s t u v))
    context.cache_properties(create_fake_element_properties(names, property_prefix, attributes))
  end

  def create_fake_element_properties(names, property_prefix = raw_property_prefix, attributes = %w(p q r s t u v))
    properties = {}
    names.collect { |k| "#{property_prefix}#{k}" }.each do |key|
      attributes.each do |a|
        properties["#{key}.#{a}"] = a
      end
    end
    properties
  end
end
