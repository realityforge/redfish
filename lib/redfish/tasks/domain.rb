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
      # If false will wait until all threads associated with the domain stop before stoppping domain
      attribute :force, :type => :boolean, :default => true
      # If true use OS functionality to stop domain
      attribute :kill, :type => :boolean, :default => false

      action :create do
        check_properties

        unless File.directory?(context.domain_directory)
          do_create

          updated_by_last_action
        end
      end

      action :start do
        unless running?
          do_start

          updated_by_last_action
        end
      end

      action :stop do
        if running?
          do_stop

          updated_by_last_action
        end
      end

      action :restart do
        do_restart

        updated_by_last_action
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
        options = {}

        args = []
        args << '--checkports=false'
        args << '--savelogin=false'
        args << '--savemasterpassword=false'
        temp_file = nil
        if context.domain_password
          require 'tempfile'

          temp_file = Tempfile.new("#{context.domain_name}create")
          temp_file.write("AS_ADMIN_MASTERPASSWORD=#{context.domain_password}\nAS_ADMIN_PASSWORD=#{context.domain_password}\n")
          temp_file.close

          options[:domain_password_file] = temp_file.path
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

        begin
          context.exec('create-domain', args, options)
        ensure
          temp_file.unlink if temp_file
        end

        # Directory required for Payara 4.1.151
        create_dir("#{context.domain_directory}/bin", 0755)

        # Directories required for Payara 4.1.152
        create_dir("#{context.domain_directory}/lib", 0755)
        create_dir("#{context.domain_directory}/lib/ext", 0755)

        # This line is probably not needed outside tests...
        create_dir("#{context.domain_directory}/config", 0700)

        pass_file = context.domain_password_file_location
        File.open(pass_file, 'wb') do |f|
          f.write <<-PASS
AS_ADMIN_MASTERPASSWORD=#{context.domain_password}
AS_ADMIN_PASSWORD=#{context.domain_password}
          PASS
        end
        FileUtils.chmod 0400, pass_file
        FileUtils.chown context.system_user, context.system_group, pass_file if context.system_user || context.system_group
        cmd = "#{context.domain_directory}/bin/asadmin"
        File.open(cmd, 'wb') do |f|
          f.write <<-SH
#!/bin/sh

#{context.build_command('"$@"', [], :remote_command => true, :terse => false, :echo => true, :sudo => false).join(' ')}
          SH
        end
        FileUtils.chmod 0700, cmd
        FileUtils.chown context.system_user, context.system_group, cmd if context.system_user || context.system_group

        FileUtils.rm_f "#{context.domain_directory}/docroot/index.html"
      end

      def create_dir(directory, mode)
        FileUtils.mkdir_p(directory)
        FileUtils.chmod mode, directory
        FileUtils.chown context.system_user, context.system_group, directory if context.system_user || context.system_group
      end

      def do_start
        args = []
        args << '--domaindir' << context.domains_directory.to_s if context.domains_directory

        args << context.domain_name.to_s

        context.exec('start-domain', args)
      end

      def do_stop
        args = []
        args << "--force=#{self.force}"
        args << "--kill=#{self.kill}"
        args << '--domaindir' << context.domains_directory.to_s if context.domains_directory

        args << context.domain_name.to_s

        context.exec('stop-domain', args)
      end

      def do_restart
        args = []
        args << "--force=#{self.force}"
        args << "--kill=#{self.kill}"
        args << '--domaindir' << context.domains_directory.to_s if context.domains_directory

        args << context.domain_name.to_s

        context.exec('restart-domain', args)
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

      def running?
        args = []
        args << '--domaindir' << context.domains_directory.to_s if context.domains_directory
        (context.exec('list-domains', args, :terse => true, :echo => false) =~ /^#{Regexp.escape(context.domain_name)} running$/)
      end
    end
  end
end
