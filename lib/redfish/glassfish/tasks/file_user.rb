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
      class FileUser < AsadminTask
        private

        attribute :realm_name, :kind_of => String, :required => true, :identity_field => true
        attribute :username, :kind_of => String, :required => true, :identity_field => true
        attribute :password, :kind_of => [String, NilClass], :default => nil
        attribute :groups, :kind_of => Array, :default => []

        action :create do
          if present?
            if current_groups.sort.uniq != groups.sort.uniq
              password_file = create_password_file
              args = ['--authrealmname', self.realm_name]
              args += ['--groups', self.groups.join(':')] if self.groups.size > 0
              args += [self.username]
              begin
                context.exec('update-file-user', args, :domain_password_file => password_file)
              ensure
                FileUtils.rm_f password_file
              end
              context.require_restart!

              updated_by_last_action
            end
          else
            password_file = create_password_file
            args = ['--authrealmname', self.realm_name]
            args += ['--groups', self.groups.join(':')] if self.groups.size > 0
            args += [self.username]

            begin
              context.exec('create-file-user', args, :domain_password_file => password_file)
            ensure
              FileUtils.rm_f password_file
            end
            updated_by_last_action
          end
        end

        action :destroy do
          if present?

            context.exec('delete-file-user', ['--authrealmname', self.realm_name, self.username])

            updated_by_last_action
          end
        end

        def create_password_file
          temp_file = Tempfile.new("#{context.domain_name}file_user")

          temp_file.write IO.read(context.domain_password_file) if context.domain_password_file
          temp_file.write "AS_ADMIN_USERPASSWORD=#{self.password}\n"
          temp_file.close

          temp_file.path
        end

        def current_groups
          context.exec('list-file-groups', ['--authrealmname', self.realm_name, '--name', self.username], :terse => true, :echo => false).gsub("list-file-groups Successful\n",'').split("\n")
        end

        def present?
          (context.exec('list-file-users', ['--authrealmname', self.realm_name], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.username)}$/)
        end
      end
    end
  end
end
