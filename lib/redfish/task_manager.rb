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

module Redfish
  class TaskManager
    class << self
      @@task_map = {}
      @@abstract_types = []

      def tasks(group = nil)
        task_map(group).values
      end

      def register_task(type)
        name = type.registered_name
        group = type.registered_group
        raise "Task already registered with name '#{name}' when attempting to register #{type}" if task_map(group)[name]
        Redfish.debug("Registering task '#{name}' with type #{type}")
        task_map(group)[name] = type
      end

      def mark_as_abstract!(type)
        @@abstract_types << type
      end

      # Return the set of keys under which tasks are registered
      def registered_task_names(group = nil)
        task_map(group).keys.dup
      end

      def create_task(group, name, options = {})
        type = task_map(group)[name]
        raise "No task registered with name '#{name}'" unless type
        raise "Attempted to instantiate abstract task with name '#{name}'" if @@abstract_types.include?(type)
        t = type.new
        t.options = options
        yield t if block_given?
        t
      end

      private

      def task_map(group)
        @@task_map[group || ''] ||= {}
      end
    end
  end
end
