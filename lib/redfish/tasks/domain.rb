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
    class Domain < AsadminTask
      private

      attribute :template, :kind_of => String, :default => nil
      # Name used in the self-signed certificate. If not specified will assume the hostname
      attribute :common_name, :kind_of => String, :default => nil
      # A set of domain properties to use to configure the domain.
      attribute :properties, :kind_of => Hash, :default => {}

      action :create do
        check_properties

        unless File.directory?(context.domain_directory)
          do_create

          updated_by_last_action
        end
      end

      action :destroy do
        if File.directory?(context.domain_directory)
          do_destroy

          updated_by_last_action
        end
      end

      def check_properties
        if self.properties['domain.adminPort'] && self.properties['domain.adminPort'].to_s != context.domain_admin_port.to_s
          raise "Domain property 'domain.adminPort' is set to '#{self.properties['domain.adminPort']}' which does not match context configuration value of '#{context.domain_admin_port}'"
        end

        self.properties.keys.each do |domain_property|
          unless valid_properties.include?(domain_property)
            raise "Unknown domain property '#{domain_property}' specified."
          end
        end
      end

      def do_create
        args = []
        args << '--checkports=false'
        args << '--savelogin=false'
        args << '--savemasterpassword=false'
        if context.domain_password_file
          args << '--nopassword=false'
          args << '--usemasterpassword=true'
        end
        args << '--domaindir' << context.domains_directory.to_s if context.domains_directory
        args << '--template' << self.template.to_s if self.template
        args << '--keytooloptions' << "CN=#{self.common_name}" if self.common_name

        # Ensure admin port property is correctly set
        properties = self.properties.dup
        properties['domain.adminPort'] = context.domain_admin_port
        args << '--domainproperties' << encode_parameters(properties)

        args << context.domain_name.to_s

        context.exec('create-domain', args)
      end

      def do_destroy
        args = []
        args << '--domaindir' << context.domains_directory.to_s if context.domains_directory

        args << context.domain_name.to_s

        context.exec('delete-domain', args)
      end

      def valid_properties
        %w(domain.adminPort domain.instancePort domain.jmxPort http.ssl.port java.debugger.port jms.port orb.listener.port orb.mutualauth.port orb.ssl.port osgi.shell.telnet.port)
      end

      def instance_key
        "name=#{context.domain_name} dir=#{context.domain_directory}"
      end
    end
  end
end
