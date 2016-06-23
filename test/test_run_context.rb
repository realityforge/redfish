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

class Redfish::TestRunContext < Redfish::TestCase
  class CollectorListener
    attr_reader :on_task_start_execution_record
    attr_reader :on_task_complete_execution_record
    attr_reader :on_task_error_execution_record

    def on_task_start(execution_record)
      @on_task_start_execution_record = execution_record
    end

    def on_task_complete(execution_record)
      @on_task_complete_execution_record = execution_record
    end

    def on_task_error(execution_record)
      @on_task_error_execution_record = execution_record
    end
  end

  class ::Redfish::Tasks::Glassfish::MyTestTask2 < Redfish::Task
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

    action :action3 do
      raise 'Something broke!'
    end
  end

  def test_basic_interaction
    run_context = Redfish::RunContext.new(create_simple_context(Redfish::Executor.new))

    # Add a listener that has no listener methods. Should not cause any issues
    run_context.listeners << Object.new

    # Add an actual listener
    listener = CollectorListener.new
    run_context.listeners << listener

    assert_equal run_context.execution_records.size, 0

    run_context.task('my_test_task2').action(:action1)

    assert_equal run_context.execution_records.size, 1

    execution_record = run_context.execution_records[0]

    assert !execution_record.task.action1_ran
    assert !execution_record.task.action2_ran

    assert listener.on_task_start_execution_record.nil?
    assert listener.on_task_complete_execution_record.nil?
    assert listener.on_task_error_execution_record.nil?

    run_context.converge

    assert execution_record.task.action1_ran
    assert !execution_record.task.action2_ran

    assert !execution_record.action_performed_update?

    assert_equal listener.on_task_start_execution_record, execution_record
    assert_equal listener.on_task_complete_execution_record, execution_record
    assert listener.on_task_error_execution_record.nil?
  end

  def test_converge_that_triggers_action
    run_context = Redfish::RunContext.new(create_simple_context(Redfish::Executor.new))

    # Add a listener that has no listener methods. Should not cause any issues
    run_context.listeners << Object.new

    # Add an actual listener
    listener = CollectorListener.new
    run_context.listeners << listener

    run_context.task('my_test_task2').action(:action2)
    assert_equal run_context.execution_records.size, 1
    execution_record = run_context.execution_records[0]

    assert !execution_record.task.action1_ran
    assert !execution_record.task.action2_ran

    assert listener.on_task_start_execution_record.nil?
    assert listener.on_task_complete_execution_record.nil?
    assert listener.on_task_error_execution_record.nil?

    run_context.converge

    assert !execution_record.task.action1_ran
    assert execution_record.task.action2_ran

    assert execution_record.action_performed_update?

    assert_equal listener.on_task_start_execution_record, execution_record
    assert_equal listener.on_task_complete_execution_record, execution_record
    assert listener.on_task_error_execution_record.nil?
  end

  def test_converge_that_triggers_error
    run_context = Redfish::RunContext.new(create_simple_context(Redfish::Executor.new))

    # Add a listener that has no listener methods. Should not cause any issues
    run_context.listeners << Object.new

    # Add an actual listener
    listener = CollectorListener.new
    run_context.listeners << listener

    run_context.task('my_test_task2').action(:action3)
    assert_equal run_context.execution_records.size, 1
    execution_record = run_context.execution_records[0]

    assert !execution_record.task.action1_ran
    assert !execution_record.task.action2_ran

    assert listener.on_task_start_execution_record.nil?
    assert listener.on_task_complete_execution_record.nil?
    assert listener.on_task_error_execution_record.nil?

    assert_raise(RuntimeError) { run_context.converge }

    assert !execution_record.task.action1_ran
    assert !execution_record.task.action2_ran

    assert !execution_record.action_performed_update?

    assert_equal listener.on_task_start_execution_record, execution_record
    assert listener.on_task_complete_execution_record.nil?
    assert_equal listener.on_task_error_execution_record, execution_record
  end
end
