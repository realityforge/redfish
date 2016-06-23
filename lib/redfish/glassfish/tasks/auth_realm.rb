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
      class AuthRealm < BaseResourceTask
        PROPERTY_PREFIX = 'configs.config.server-config.security-service.auth-realm.'

        private

        attribute :name, :kind_of => String, :required => true, :identity_field => true
        attribute :classname, :kind_of => String, :required => true
        attribute :properties, :kind_of => Hash, :default => {}

        action :create do
          create(resource_property_prefix)
        end

        action :destroy do
          destroy(resource_property_prefix)
        end

        def immutable_local_properties
          ['classname']
        end

        def resource_property_prefix
          "#{PROPERTY_PREFIX}#{self.name}."
        end

        def properties_to_record_in_create
          {'name' => self.name}
        end

        def properties_to_set_in_create
          property_map = {}

          collect_property_sets(resource_property_prefix, property_map)

          property_map['classname'] = self.classname

          property_map
        end

        def do_create
          args = []

          args << '--classname' << self.classname.to_s
          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << self.name.to_s

          context.exec('create-auth-realm', args)
        end

        def do_destroy
          context.exec('delete-auth-realm', [self.name])
        end

        def add_resource_ref?
          false
        end

        def present?
          (context.exec('list-auth-realms', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end
      end
    end
  end
end
