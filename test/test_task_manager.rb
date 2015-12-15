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

require File.expand_path('../helper', __FILE__)

class Redfish::TestTaskManager < Redfish::TestCase

  def test_tasks_registered_correctly
    assert Redfish::TaskManager.registered_task_names.include?('property')
    assert Redfish::TaskManager.registered_task_names.include?('property_cache')
  end

  def test_duplicate_registration_fails
    error = false
    begin
      Redfish::TaskManager.register_task(Redfish::Tasks::Property)
    rescue => e
      assert_equal e.to_s, "Task already registered with name 'property' when attempting to register Redfish::Tasks::Property"
      error = true
    end
    fail('Expected to fail duplicate registration') unless error
  end

  def test_create_task_with_bad_name
    error = false
    begin
      Redfish::TaskManager.create_task('no_such_task')
    rescue => e
      assert_equal e.to_s, "No task registered with name 'no_such_task'"
      error = true
    end
    fail('Expected to fail as no such registration') unless error
  end

  def test_create_task
    pc = Redfish::TaskManager.create_task('property_cache')
    assert pc.is_a?(Redfish::Tasks::PropertyCache)

    t = Redfish::TaskManager.create_task('property',
                                         'name' => 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping',
                                         'value' => 'true')
    assert t.is_a?(Redfish::Tasks::Property)
    assert_equal t.name, 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    assert_equal t.value, 'true'
  end

  def test_create_abstract_task_produces_error
    error = false
    begin
      Redfish::TaskManager.create_task('asadmin_task')
    rescue => e
      assert_equal e.to_s, "Attempted to instantiate abstract task with name 'asadmin_task'"
      error = true
    end
    fail('Expected to fail as no such registration') unless error
  end
end
