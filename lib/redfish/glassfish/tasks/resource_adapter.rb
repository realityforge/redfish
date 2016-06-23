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
      class ResourceAdapter < BaseResourceTask
        PROPERTY_PREFIX = 'resources.resource-adapter-config.'

        private

        attribute :name, :kind_of => String, :required => true, :identity_field => true
        attribute :thread_pool_name, :kind_of => String, :default => nil
        attribute :properties, :kind_of => Hash, :default => {}

        action :create do
          create(resource_property_prefix)
        end

        action :destroy do
          destroy(resource_property_prefix)
        end

        def resource_property_prefix
          "#{PROPERTY_PREFIX}#{self.name}."
        end

        def properties_to_record_in_create
          {'object-type' => 'user', 'resource-adapter-name' => self.name, 'deployment-order' => '100'}
        end

        def properties_to_set_in_create
          property_map = {}

          collect_property_sets(resource_property_prefix, property_map)

          property_map['thread-pool-ids'] = self.thread_pool_name

          property_map
        end

        def do_create
          args = []

          args << '--threadpoolid' << self.thread_pool_name.to_s
          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << self.name.to_s

          context.exec('create-resource-adapter-config', args)
        end

        def do_destroy
          context.exec('delete-resource-adapter-config', [self.name])
        end

        def add_resource_ref?
          false
        end

        def present?
          (context.exec('list-resource-adapter-configs', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end
      end
    end
  end
end
