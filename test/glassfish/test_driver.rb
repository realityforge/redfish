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

class Redfish::TestDriver < Redfish::TestCase
  class CollectorListener
    attr_reader :on_task_start_execution_records
    attr_reader :on_task_complete_execution_records
    attr_reader :on_task_error_execution_records

    def on_task_start(execution_record)
      @on_task_start_execution_records ||= []
      @on_task_start_execution_records << execution_record
    end

    def on_task_complete(execution_record)
      @on_task_complete_execution_records ||= []
      @on_task_complete_execution_records << execution_record
    end

    def on_task_error(execution_record)
      @on_task_error_execution_records ||= []
      @on_task_error_execution_records << execution_record
    end
  end

  def test_basic_workflow
    Redfish::TaskManager.tasks('glassfish').each do |task|
      task.any_instance.expects(:perform_action).with(anything).at_least(0)
    end

    definition = Redfish::DomainDefinition.new('appserver')

    Redfish::Config.default_glassfish_home = '/urs/local/glassfish'

    listener = CollectorListener.new
    context = Redfish::Driver.configure_domain(definition, :listeners => [listener])

    assert_equal context.listeners.size, 1
    assert_equal context.listeners[0], listener

    assert context.execution_records.size > 0

    context.execution_records.each do |record|
      assert record.action_finished?
    end
  end

  def test_configure_when_incomplete
    definition = Redfish::DomainDefinition.new('appserver')
    definition.complete = false
    assert_raise(RuntimeError, "Attempting to configure domain 'appserver' using and incomplete domain definition 'appserver'") { Redfish::Driver.configure_domain(definition) }
  end
end
