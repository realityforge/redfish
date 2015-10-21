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

require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestProperty < Redfish::Tasks::BaseTaskTest
  def test_set_property_no_cache_and_not_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),equals('get'),equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping)),equals(:terse => true, :echo => false)).returns('')
    executor.expects(:exec).with(equals(t.context),equals('set'),equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true)),equals(:terse => true, :echo => false)).returns('')

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end

  def test_set_property_no_cache_and_already_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),equals('get'),equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping)),equals(:terse => true, :echo => false)).returns('configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true')

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_set_property_cache_and_not_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'false')

    executor.expects(:exec).with(equals(t.context),equals('set'),equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true)),equals(:terse => true, :echo => false)).returns('')

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
    assert_equal t.context.property_cache['configs.config.server-config.security-service.activate-default-principal-to-role-mapping'], 'true'
  end

  def test_set_property_cache_and_set
    t = new_task

    t.context.cache_properties('configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'true')

    t.name = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

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
