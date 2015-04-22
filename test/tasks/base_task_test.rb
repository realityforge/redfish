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
    task_name = self.class.name.to_s.split('::').last.gsub(/^Test/,'')
    t = Redfish::Tasks.const_get(task_name).new
    t.context = create_simple_context(executor)
    t
  end
end
