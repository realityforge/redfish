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

      def register_task(type)
        name = type.registered_name
        raise "Task already registered with name '#{name}' when attempting to register #{type}" if @@task_map[name]
        Redfish.debug("Registering task '#{name}' with type #{type}")
        @@task_map[name] = type
      end

      def mark_as_abstract!(type)
        @@abstract_types << type
      end

      # Return the set of keys under which tasks are registered
      def registered_task_names
        @@task_map.keys.dup
      end

      def create_task(context, name, options = {})
        type = @@task_map[name]
        raise "No task registered with name '#{name}'" unless type
        raise "Attempted to instantiate abstract task with name '#{name}'" if @@abstract_types.include?(type)
        t = type.new
        t.context = context
        t.options = options
        yield t if block_given?
        t
      end
    end
  end
end
