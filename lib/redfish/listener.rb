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

  class BasicListener
    def on_task_start(execution_record)
      puts "Redfish Task #{execution_record} starting" if ENV['REDFISH_DEBUG'] == 'true'
    end

    def on_task_complete(execution_record)
      if execution_record.action_performed_update? && is_task_interesting?(execution_record)
        puts "Redfish Task #{execution_record} performed action"
      else
        puts "Redfish Task #{execution_record} completed" if ENV['REDFISH_DEBUG'] == 'true'
      end
    end

    def on_task_error(execution_record)
      puts "Redfish Task #{execution_record} resulted in error"
    end

    def is_task_interesting?(execution_record)
      return false if execution_record.action == :ensure_active && execution_record.task.class.registered_name == 'domain'
      return false if execution_record.action == :create && execution_record.task.class.registered_name == 'property_cache'
      return false if execution_record.action == :destroy && execution_record.task.class.registered_name == 'property_cache'
      true
    end
  end
end
