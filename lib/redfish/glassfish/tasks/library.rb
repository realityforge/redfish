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
      class Library < AsadminTask
        LIBRARY_TYPES = %w(common ext app)

        private

        attribute :library_type, :equal_to => LIBRARY_TYPES, :default => 'common', :identity_field => true
        attribute :file, :kind_of => String, :required => true, :identity_field => true
        attribute :upload, :type => :boolean, :default => false
        attribute :require_restart, :type => :boolean, :default => false

        action :create do
          unless present?
            args = []
            args << '--type' << self.library_type.to_s
            args << '--upload' << self.upload.to_s
            args << self.file.to_s

            context.exec('add-library', args)

            updated_by_last_action
          end
        end

        action :destroy do
          if present?
            context.exec('remove-library', ['--type', self.library_type.to_s, File.basename(self.file)])

            updated_by_last_action
          end
        end

        def present?
          (context.exec('list-libraries', ['--type', self.library_type.to_s], :terse => true, :echo => false) =~ /^#{Regexp.escape(File.basename(self.file))}$/)
        end
      end
    end
  end
end
