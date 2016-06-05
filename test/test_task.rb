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

class Redfish::TestTask < Redfish::TestCase
  class MyTestTask < Redfish::Task
    attribute :container, :kind_of => String, :identity_field => true
    attribute :a, :kind_of => String, :required => true, :identity_field => true
    attribute :b, :kind_of => [TrueClass, FalseClass], :default => false
    attribute :c, :equal_to => [true, false, 'true', 'false'], :default => 'false'
    attribute :d, :kind_of => String, :regex => /^X+$/
    attribute :e, :type => :integer, :default => '1'
    attribute :f, :type => :boolean, :default => 'false'

    attr_accessor :action1_ran
    attr_accessor :action2_ran

    private

    action :action1 do
      @action1_ran = true
    end

    action :action2 do
      @action2_ran = true
      updated_by_last_action
    end
  end

  def test_identity_field
    task = new_task
    task.container = 'Container'
    task.a = 'A'
    assert_equal task.instance_key, 'Container::A'
    assert_equal task.to_s, 'my_test_task[Container::A]'
  end

  def test_registered_name
    assert_equal MyTestTask.registered_name, 'my_test_task'
  end

  def test_required_raises_exception_if_unset
    begin
      new_task.a
    rescue
      return
    end

    fail('Expected to fail when accessing a before setting')
  end

  def test_invalid_value_by_kind_of
    begin
      new_task.a = 1
    rescue => e
      assert_equal e.to_s, "Invalid value passed to attribute 'a' on my_test_task expected to be one of [String] but is of type Fixnum. Value = 1"
      return
    end

    fail('Expected to fail due to bad type')
  end

  def test_invalid_value_by_equal_to
    begin
      new_task.c = 1
    rescue => e
      assert_equal e.to_s, "Invalid value passed to attribute 'c' expected to be one of [true, false, \"true\", \"false\"] but is 1"
      return
    end

    fail('Expected to fail due to bad type')
  end

  def test_invalid_value_by_kind_of_array
    begin
      new_task.b = 1
    rescue => e
      assert_equal e.to_s, "Invalid value passed to attribute 'b' on my_test_task expected to be one of [TrueClass, FalseClass] but is of type Fixnum. Value = 1"
      return
    end

    fail('Expected to fail due to bad type')
  end

  def test_invalid_value_by_regex
    begin
      new_task.d = 'X1'
    rescue => e
      assert_equal e.to_s, "Invalid value passed to attribute 'd' expected to match regex /^X+$/ but is \"X1\""
      return
    end

    fail('Expected to fail due to bad value not matching regex')
  end

  def test_type_boolean
    new_task.f = true
    new_task.f = false
    new_task.f = 'true'
    new_task.f = 'false'
    assert_raise(RuntimeError) {new_task.f = 'X'}
  end

  def test_type_integer
    new_task.e = 1
    new_task.e = -4343
    new_task.e = '23'
    new_task.e = '${SOME_VAR}'
    assert_raise(RuntimeError) {new_task.e = 'X'}
  end

  def test_set
    mt = new_task do |t|
      t.a = 'a'
      t.b = true
      t.c = 'true'
      t.d = 'XXX'
      t.e = 33
      t.f = true
    end

    assert_equal mt.a, 'a'
    assert_equal mt.b, true
    assert_equal mt.c, 'true'
    assert_equal mt.d, 'XXX'
    assert_equal mt.e, 33
    assert_equal mt.f, true
  end

  def test_defaults
    mt = new_task do |t|
      t.a = 'a'
    end

    assert_equal mt.a, 'a'
    assert_equal mt.b, false
    assert_equal mt.c, 'false'
    assert_equal mt.d, nil
    assert_equal mt.e, '1'
    assert_equal mt.f, 'false'
  end

  def test_non_existent_action
    mt = new_task do |t|
      t.a = 'a'
    end

    begin
      mt.perform_action(:B)
    rescue => e
      assert_equal e.to_s, 'No such action B'
      return
    end

    fail('Expected to fail due to bad action')
  end

  def test_action
    mt = new_task do |t|
      t.a = 'a'
    end

    assert_equal mt.action1_ran, nil
    mt.perform_action(:action1)
    assert_equal mt.action1_ran, true
    assert_equal mt.updated_by_last_action?, false
  end

  def test_action_that_causes_update
    mt = new_task do |t|
      t.a = 'a'
    end

    assert_equal mt.action2_ran, nil
    mt.perform_action(:action2)
    assert_equal mt.action2_ran, true
    assert_equal mt.updated_by_last_action?, true
  end

  def new_task
    MyTestTask.new do |t|
      t.run_context = Redfish::RunContext.new(new_context)
      yield t if block_given?
    end
  end

  def new_context
    create_simple_context
  end
end
