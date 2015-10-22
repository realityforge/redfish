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

module Redfish #nodoc

  class RunContext
    def initialize(app_context)
      @app_context = app_context
      @execution_records = []
    end

    def execution_records
      @execution_records.dup
    end

    def task(name, options = {}, &block)
      execution_record = TaskExecutionRecord.new(@app_context.task(name, options, &block))
      add_execution_record(execution_record)
      execution_record
    end

    def converge
      execution_records.each do |execution_record|
        execution_record.action_started_at = Time.now
        begin
          execution_record.task.perform_action(execution_record.action)
          execution_record.action_performed_update! if execution_record.task.updated_by_last_action?
        rescue Exception => e
          execution_record.action_error = e
          raise e
        ensure
          execution_record.action_finished_at = Time.now
        end
      end
    end

    private

    def add_execution_record(action_record)
      @execution_records << action_record
    end
  end
end

