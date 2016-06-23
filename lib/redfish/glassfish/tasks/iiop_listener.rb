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
      class IiopListener < BaseResourceTask
        PROPERTY_PREFIX = 'configs.config.server-config.iiop-service.iiop-listener.'

        private

        attribute :name, :kind_of => String, :required => true, :identity_field => true

        # Either the IP address or the hostname (resolvable by DNS).
        attribute :address, :kind_of => String, :default => '0.0.0.0'
        # The IIOP port number.
        attribute :port, :type => :integer, :default => 1072
        # If set to true, the IIOP listener runs SSL. You can turn SSL2 or SSL3 ON or OFF and set ciphers using an SSL element. The security setting globally enables or disables SSL by making certificates available to the server instance.
        attribute :securityenabled, :type => :boolean, :default => false
        # If set to true, the IIOP listener is enabled at runtime.
        attribute :enabled, :type => :boolean, :default => true
        # Optional attribute name/value pairs for configuring the IIOP listener.
        attribute :properties, :kind_of => Hash, :default => {}
        # Flag indicating wheter jms service should be lazily initialized.
        attribute :lazy_init, :type => :boolean, :default => true

        action :create do
          create(resource_property_prefix)
        end

        action :destroy do
          destroy(resource_property_prefix)
        end

        def properties_to_record_in_create
          {'id' => self.name, 'lazy-init' => 'false'}
        end

        def properties_to_set_in_create
          property_map = {}

          collect_property_sets(resource_property_prefix, property_map)

          property_map['address'] = self.address
          property_map['enabled'] = self.enabled.to_s
          property_map['port'] = self.port.to_s
          property_map['security-enabled'] = self.securityenabled.to_s
          property_map['lazy-init'] = self.lazy_init.to_s

          property_map
        end

        def do_create
          args = []

          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << '--listeneraddress' << self.address.to_s
          args << '--iiopport' << self.port.to_s
          args << '--securityenabled' << self.securityenabled.to_s
          args << '--enabled' << self.enabled.to_s
          args << self.name.to_s

          context.exec('create-iiop-listener', args)
        end

        def post_create_hook
          t = run_context.task('property', 'name' => "#{resource_property_prefix}lazy-init", 'value' => self.lazy_init.to_s)
          t.action(:set)
          run_context.converge_task(t)
          updated_by_last_action if t.task.updated_by_last_action?
        end

        def do_destroy
          context.exec('delete-iiop-listener', [self.name])
        end

        def present?
          (context.exec('list-iiop-listeners', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end

        def add_resource_ref?
          false
        end

        def resource_property_prefix
          "#{PROPERTY_PREFIX}#{self.name}."
        end
      end
    end
  end
end
