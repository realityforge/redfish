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
    class JmsHost < BaseResourceTask
      private

      attribute :name, :kind_of => String, :required => true, :identity_field => true
      # The host name for the JMS service.
      attribute :host, :kind_of => String, :required => true
      # The port number used by the JMS service.
      attribute :port, :kind_of => Integer, :required => true
      # The user name for the JMS service.
      attribute :admin_username, :kind_of => String, :required => true
      # The password for the JMS service.
      attribute :admin_password, :kind_of => String, :required => true

      action :create do
        create(resource_property_prefix)
      end

      action :destroy do
        destroy(resource_property_prefix)
      end

      def resource_property_prefix
        "configs.config.server-config.jms-service.jms-host.#{self.name}."
      end

      def properties_to_record_in_create
        {'lazy-init' => 'true', 'name' => self.name}
      end

      def properties_to_set_in_create
        property_map = {}

        property_map['admin-user'] = self.admin_username
        property_map['admin-password'] = self.admin_password
        property_map['host'] = self.host
        property_map['port'] = self.port
        property_map
      end

      def do_create
        args = []

        args << '--mqhost' << self.host.to_s
        args << '--mqport' << self.port.to_s
        args << '--mquser' << self.admin_username.to_s
        args << '--mqpassword' << self.admin_password.to_s
        args << self.name.to_s

        context.exec('create-jms-host', args)
      end

      def do_destroy
        context.exec('delete-jms-host', [self.name])
      end

      def present?
        (context.exec('list-jms-hosts', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
      end
    end
  end
end
