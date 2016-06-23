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
      class LibraryCleaner < BaseCleanerTask
        attribute :library_type, :equal_to => Library::LIBRARY_TYPES, :identity_field => true, :default => 'common'

        protected

        def additional_resource_properties
          {:library_type => self.library_type}
        end

        def resource_name_key
          'file'
        end

        def elements_to_remove
          self.existing_elements - self.expected.collect { |f| File.basename(f) }
        end

        def existing_elements
          context.exec('list-libraries', ['--type', self.library_type.to_s], :terse => true, :echo => false).split("\n")
        end
      end
    end
  end
end
