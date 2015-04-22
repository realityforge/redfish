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
    attribute :a, :kind_of => String, :required => true
    attribute :b, :kind_of => [TrueClass, FalseClass], :default => false
    attribute :c, :equal_to => [true, false, 'true', 'false'], :default => 'false'
    attribute :d, :kind_of => String, :regex => /^X+$/

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
      assert_equal e.to_s, "Invalid value passed to attribute 'a' expected to be one of [String] but is of type Fixnum"
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
      assert_equal e.to_s, "Invalid value passed to attribute 'b' expected to be one of [TrueClass, FalseClass] but is of type Fixnum"
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

  def test_set
    mt = new_task do |t|
      t.a = 'a'
      t.b = true
      t.c = 'true'
      t.d = 'XXX'
    end

    assert_equal mt.a, 'a'
    assert_equal mt.b, true
    assert_equal mt.c, 'true'
    assert_equal mt.d, 'XXX'
  end

  def test_defaults
    mt = new_task do |t|
      t.a = 'a'
    end

    assert_equal mt.a, 'a'
    assert_equal mt.b, false
    assert_equal mt.c, 'false'
    assert_equal mt.d, nil
  end

  def test_non_existent_action
    mt = new_task do |t|
      t.a = 'a'
    end

    begin
      mt.perform_action(:B)
    rescue => e
      assert_equal e.to_s, "No such action B"
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
      t.context = new_context
      yield t if block_given?
    end
  end

  def new_context
    Redfish::Context.new(Redfish::Executor.new, '/opt/payara-4.1.151/', 'domain1', 4848, false, 'admin', nil, :terse => false, :echo => true)
  end
end
