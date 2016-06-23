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
      class ManagedThreadFactory < BaseResourceTask
        PROPERTY_PREFIX = 'resources.managed-thread-factory.'

        private

        attribute :name, :kind_of => String, :required => true, :identity_field => true

        # Determines whether the resource is enabled at runtime.
        attribute :enabled, :type => :boolean, :default => true
        # Determines whether container contexts are propagated to threads. If set to true, the contexts specified in the --contextinfo option are propagated. If set to false, no contexts are propagated and the --contextinfo option is ignored.
        attribute :context_info_enabled, :type => :boolean, :default => true
        # Specifies individual container contexts to propagate to threads. Valid values are Classloader, JNDI, Security, and WorkArea. Values are specified in a comma-separated list and are case-insensitive. All contexts are propagated by default.
        attribute :context_info, :kind_of => String, :default => 'Classloader,JNDI,Security,WorkArea'
        # Specifies the priority to assign to created threads.
        attribute :thread_priority, :type => :integer, :default => 5
        # Descriptive details about the resource.
        attribute :description, :kind_of => String, :default => ''
        attribute :properties, :kind_of => Hash, :default => {}
        attribute :deployment_order, :kind_of => Fixnum, :default => 100

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
          {'object-type' => 'user', 'jndi-name' => self.name, 'deployment-order' => '100'}
        end

        def properties_to_set_in_create
          property_map = {}

          collect_property_sets(resource_property_prefix, property_map)

          property_map['description'] = self.description
          property_map['context-info-enabled'] = self.context_info_enabled
          property_map['context-info'] = self.context_info
          property_map['enabled'] = self.enabled
          property_map['thread-priority'] = self.thread_priority

          property_map
        end

        def do_create
          args = []

          args << '--enabled' << self.enabled.to_s
          args << '--contextinfoenabled' << self.context_info_enabled.to_s
          args << '--contextinfo' << self.context_info.to_s
          args << '--threadpriority' << self.thread_priority.to_s
          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << '--description' << self.description.to_s
          args << self.name.to_s

          context.exec('create-managed-thread-factory', args)
        end

        def do_destroy
          context.exec('delete-managed-thread-factory', [self.name])
        end

        def present?
          (context.exec('list-managed-thread-factorys', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end
      end
    end
  end
end
