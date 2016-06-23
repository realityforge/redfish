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
      class ConnectorConnectionPoolCleaner < BaseCleanerTask
        attribute :resource_adapter_name, :kind_of => String, :required => true, :identity_field => true

        def cascade_clean(element)
          t = run_context.task('connector_resource_cleaner', 'connector_pool_name' => element, 'expected' => [])
          t.action(:clean)
          t.converge
          t
        end

        protected

        def existing_elements
          elements_with_prefix_and_property(property_prefix, 'resource-adapter-name', self.resource_adapter_name)
        end
      end
    end
  end
end
