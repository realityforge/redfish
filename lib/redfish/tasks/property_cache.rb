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
    class PropertyCache < AsadminTask

      private

      action :create do
        properties = load_properties('*')

        skip = false
        if context.property_cache?
          if context.property_cache.properties != properties
            context.remove_property_cache
          else
            skip = true
          end
        end

        unless skip
          context.cache_properties(properties)
          updated_by_last_action
        end
      end

      action :destroy do
        if context.property_cache?
          context.remove_property_cache
          updated_by_last_action
        end
      end
    end
  end
end
