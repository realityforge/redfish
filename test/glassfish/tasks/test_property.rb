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

class Redfish::Tasks::Glassfish::TestProperty < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_interpret_create
    data = {'properties' => {'configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'true'}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('set'),
                                 equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true)),
                                 equals(:terse => true, :echo => false)).
      returns('')

    perform_interpret(context, data, true, :set)
  end

  def test_interpret_create_using_interpolation
    data = {'properties' => {'some.config' => '{{domain_name}}'}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('set'),
                                 equals(%w(some.config=domain1)),
                                 equals(:terse => true, :echo => false)).
      returns('')

    perform_interpret(context, data, true, :set)
  end

  def test_interpret_create_when_exists
    data = {'properties' => {'configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'true'}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true')

    perform_interpret(context, data, false, :set)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'

    assert_equal t.to_s, 'property[configs.config.server-config.security-service.activate-default-principal-to-role-mapping]'
  end

  def test_set_property_no_cache_and_not_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping)), equals(:terse => true, :echo => false)).returns('')
    executor.expects(:exec).with(equals(t.context), equals('set'), equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true)), equals(:terse => true, :echo => false)).returns('')

    assert !t.context.restart_required?

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_set_property_no_cache_and_not_set_with_require_restart_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping)), equals(:terse => true, :echo => false)).returns('')
    executor.expects(:exec).with(equals(t.context), equals('set'), equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true)), equals(:terse => true, :echo => false)).returns('')

    assert !t.context.restart_required?

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.require_restart = true
    t.perform_action(:set)

    assert t.context.restart_required?

    ensure_task_updated_by_last_action(t)
  end

  def test_set_property_no_cache_and_already_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping)), equals(:terse => true, :echo => false)).returns('configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true')

    assert !t.context.restart_required?

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    assert !t.context.restart_required?

    ensure_task_not_updated_by_last_action(t)
  end

  def test_set_property_cache_and_not_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'false')

    executor.expects(:exec).with(equals(t.context), equals('set'), equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true)), equals(:terse => true, :echo => false)).returns('')

    assert !t.context.restart_required?

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    assert !t.context.restart_required?

    ensure_task_updated_by_last_action(t)
    assert_equal t.context.property_cache['configs.config.server-config.security-service.activate-default-principal-to-role-mapping'], 'true'
  end

  def test_set_property_cache_and_not_set_with_require_restart_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'false')

    executor.expects(:exec).with(equals(t.context), equals('set'), equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true)), equals(:terse => true, :echo => false)).returns('')

    assert !t.context.restart_required?

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.require_restart = true
    t.perform_action(:set)

    assert t.context.restart_required?

    ensure_task_updated_by_last_action(t)
    assert_equal t.context.property_cache['configs.config.server-config.security-service.activate-default-principal-to-role-mapping'], 'true'
  end

  def test_set_property_cache_and_set
    t = new_task

    t.context.cache_properties('configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'true')

    assert !t.context.restart_required?

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    assert !t.context.restart_required?

    ensure_task_not_updated_by_last_action(t)
  end

  def test_ensure_when_value_not_matches
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping)),
                                 equals(:terse => true, :echo => false)).
      returns("configs.config.server-config.security-service.activate-default-principal-to-role-mapping=false\n")

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'

    matched = true
    begin
      t.perform_action(:ensure)
    rescue => e
      assert_equal e.message, "Property 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping' expected to be 'true'"
      matched = false
    end

    fail('Expected value to be different') if matched

    ensure_task_not_updated_by_last_action(t)
  end

  def test_ensure_when_value_matches
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping)),
                                 equals(:terse => true, :echo => false)).
      returns("configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true\n")

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    begin
      t.perform_action(:ensure)
    rescue
      fail('Expected value to be the same')
    end

    ensure_task_not_updated_by_last_action(t)
  end

  def test_ensure_when_cached_value_matches
    t = new_task

    t.context.cache_properties('configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'true')

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    begin
      t.perform_action(:ensure)
    rescue
      fail('Expected value to be the same')
    end

    ensure_task_not_updated_by_last_action(t)
  end

  def test_ensure_when_cached_value_not_matches
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'false')

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'

    matched = true
    begin
      t.perform_action(:ensure)
    rescue => e
      assert_equal e.message, "Property 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping' expected to be 'true'"
      matched = false
    end

    fail('Expected value to be different') if matched

    ensure_task_not_updated_by_last_action(t)
  end
end
