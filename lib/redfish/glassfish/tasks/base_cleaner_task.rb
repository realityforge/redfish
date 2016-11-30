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
  module Tasks
    module Glassfish
      class BaseCleanerTask < AsadminTask

        self.mark_as_abstract!

        attribute :expected, :kind_of => Array, :required => true

        protected

        def property_prefix
          Redfish::Tasks::Glassfish.
            const_get(self.class.name.to_s.split('::').last.gsub(/Cleaner$/, '')).
            const_get(:PROPERTY_PREFIX)
        end

        def clean_action
          :destroy
        end

        def resource_name_key
          'name'
        end

        def additional_resource_properties
          {}
        end

        def remove_element(element)
          cascade_clean(element)
          t = run_context.task(registered_name, additional_resource_properties.merge(resource_name_key => element))
          t.action(clean_action)
          t.converge
          t
        end

        def cascade_clean(element)
        end

        action :clean do
          self.elements_to_remove.each do |element|
            t = remove_element(element)
            updated_by_last_action if t.task.updated_by_last_action?
          end
        end

        def elements_to_remove
          self.existing_elements - self.expected
        end

        def existing_elements
          elements_with_prefix(property_prefix)
        end

        def elements_with_prefix_and_property(prefix, property_key, property_value)
          elements_with_prefix(prefix).select do |key|
            run_context.app_context.property_cache["#{prefix}#{key}.#{property_key}"] == property_value
          end
        end

        def elements_with_prefix(prefix)
          context.property_cache.get_keys_starting_with(prefix).
            collect { |k| k[prefix.size, k.size].gsub(/^([^.]+).*$/, '\1') }.sort.uniq
        end

        def task_name
          self.class.name.to_s.split('::').last.gsub(/Cleaner$/, '')
        end

        def registered_name
          Reality::Naming.underscore(task_name)
        end
      end
    end
  end
end
