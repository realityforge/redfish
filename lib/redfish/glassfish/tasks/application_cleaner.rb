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
      class ApplicationCleaner < BaseCleanerTask
        protected

        def existing_elements
          # Need this rather than relying on default exiting_elements as application names can
          # have . in them such as mercury-formats-2.5 .0.war
          context.property_cache.get_keys_starting_with(property_prefix).
            select { |k| k =~ /^.*\.object-type$/ }.
            collect { |k| k[property_prefix.size, k.size].gsub(/^(.+)\.object-type$/, '\1') }
        end
      end
    end
  end
end
