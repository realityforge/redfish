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

class Redfish::Tasks::TestPropertyCache < Redfish::Tasks::BaseTaskTest
  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    assert_equal t.to_s, 'property_cache[]'
  end

  def test_create_no_existing
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.
      expects(:exec).
      with(equals(t.context),equals('get'),equals(%w(*)),equals(:terse => true, :echo => false)).
      returns("a=1\nb=2\nc.d.e=345")

    assert_equal t.context.property_cache?, false
    t.perform_action(:create)
    ensure_task_updated_by_last_action(t)
    assert_equal t.context.property_cache?, true
    assert_equal t.context.property_cache['a'], '1'
    assert_equal t.context.property_cache['b'], '2'
    assert_equal t.context.property_cache['c.d.e'], '345'
  end

  def test_create_unless_present_when_no_existing
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.
      expects(:exec).
      with(equals(t.context),equals('get'),equals(%w(*)),equals(:terse => true, :echo => false)).
      returns("a=1\nb=2\nc.d.e=345")

    assert_equal t.context.property_cache?, false
    t.perform_action(:create_unless_present)
    ensure_task_updated_by_last_action(t)
    assert_equal t.context.property_cache?, true
    assert_equal t.context.property_cache['a'], '1'
    assert_equal t.context.property_cache['b'], '2'
    assert_equal t.context.property_cache['c.d.e'], '345'
  end

  def test_create_unless_present_existing
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    t.perform_action(:create_unless_present)
    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_existing_no_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('a' => '-1')

    executor.
      expects(:exec).
      with(equals(t.context),equals('get'),equals(%w(*)),equals(:terse => true, :echo => false)).
      returns("a=1\nb=2\nc.d.e=345")

    assert_equal t.context.property_cache?, true
    t.perform_action(:create)
    ensure_task_updated_by_last_action(t)
    assert_equal t.context.property_cache?, true
    assert_equal t.context.property_cache['a'], '1'
    assert_equal t.context.property_cache['b'], '2'
    assert_equal t.context.property_cache['c.d.e'], '345'
  end

  def test_create_existing_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('a' => '1', 'b' => '2', 'c.d.e' => '345')

    executor.
      expects(:exec).
      with(equals(t.context),equals('get'),equals(%w(*)),equals(:terse => true, :echo => false)).
      returns("a=1\nb=2\nc.d.e=345")

    assert_equal t.context.property_cache?, true
    t.perform_action(:create)
    ensure_task_not_updated_by_last_action(t)
    assert_equal t.context.property_cache?, true
    assert_equal t.context.property_cache['a'], '1'
    assert_equal t.context.property_cache['b'], '2'
    assert_equal t.context.property_cache['c.d.e'], '345'
  end

  def test_destroy
    t = new_task

    t.context.cache_properties('a' => '1', 'b' => '2', 'c.d.e' => '345')

    assert_equal t.context.property_cache?, true
    t.perform_action(:destroy)
    ensure_task_updated_by_last_action(t)
    assert_equal t.context.property_cache?, false
  end

  def test_destroy_no_existing
    t = new_task

    assert_equal t.context.property_cache?, false
    t.perform_action(:destroy)
    ensure_task_not_updated_by_last_action(t)
    assert_equal t.context.property_cache?, false
  end
end
