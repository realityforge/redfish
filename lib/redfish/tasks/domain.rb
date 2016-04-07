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
      # Maximum time to wait for the management interface to become active
      attribute :max_mx_wait_time, :type => :integer, :default => 120

      # When checking whether the domain needs a restart, only check the context and don't run asadmin command
      attribute :context_only, :type => :boolean, :default => false
      # If false will wait until all threads associated with the domain stop before stopping domain
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

      # Restart domain if pending configuration flag is true
      action :restart_if_required do
        if pending_configuration_changes?
          do_restart

          updated_by_last_action
        end
      end

      action :ensure_active do
        do_ensure_active

        updated_by_last_action
      end

      action :enable_secure_admin do
        unless secure_admin?
          do_enable_secure_admin

          updated_by_last_action
        end
      end

      action :destroy do
        if File.directory?(context.domain_directory)
          do_destroy

          updated_by_last_action
        end
      end

      # Is the domain management only accessible over ssl?
      def secure_admin?
        File.exist?("#{context.domain_directory}/config/secure.marker")
      end

      # Return true if there are pending changes to domain that require a restart
      def pending_configuration_changes?
        return true if context.restart_required?
        return false if self.context_only
        (context.exec('_get-restart-required', [], :terse => true, :echo => false) =~ /^true$/)
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

        # Remove all the unnecessary files that come with the template
        FileUtils.rm_f "#{context.domain_directory}/docroot/index.html"
        FileUtils.rm_f "#{context.domain_directory}/config/restrict.server.policy"
        FileUtils.rm_f "#{context.domain_directory}/config/javaee.server.policy"
        FileUtils.rm_rf "#{context.domain_directory}/autodeploy"
        FileUtils.rm_rf "#{context.domain_directory}/init-info"

        Dir["#{context.domain_directory}/**/.gitkeep"].each do |gitkeep|
          FileUtils.rm_f gitkeep
        end
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

      def do_restart(options = {})
        args = []
        args << "--force=#{self.force}"
        args << "--kill=#{self.kill}"
        args << '--domaindir' << context.domains_directory.to_s if context.domains_directory

        args << context.domain_name.to_s

        context.exec('restart-domain', args, options)

        do_ensure_active

        context.domain_restarted!
      end

      def do_destroy
        args = []
        args << '--domaindir' << context.domains_directory.to_s if context.domains_directory

        args << context.domain_name.to_s

        context.exec('delete-domain', args)
      end

      def do_enable_secure_admin
        context.exec('enable-secure-admin', [], :secure => false)

        # The enable-secure-admin command changes so much state it is easier to reset and start again
        context.remove_property_cache if context.property_cache?

        secure_marker_file = "#{context.domain_directory}/config/secure.marker"
        FileUtils.touch secure_marker_file
        FileUtils.chmod 0400, secure_marker_file
        FileUtils.chown context.system_user, context.system_group, secure_marker_file if context.system_user || context.system_group

        do_restart(:secure => false)
      end

      def do_ensure_active
        base_url = "http#{context.domain_secure ? 's' : ''}://127.0.0.1:#{context.domain_admin_port}"

        fail_count = 0
        loop do
          # Break out of loop if can successfully hit all these urls
          break if %w(/ /management/domain/nodes /management/domain/applications).all? do |path|
            is_url_responding_with_ok?("#{base_url}#{path}", context.domain_username, context.domain_password)
          end

          fail_count = fail_count + 1
          raise 'GlassFish failed to become operational' if fail_count > self.max_mx_wait_time
          Kernel.sleep 1
        end
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
        (context.exec('list-domains', args, :terse => true, :echo => false) =~ /^#{Regexp.escape(context.domain_name)} running(, restart required to apply configuration changes)?$/)
      end

      def is_url_responding_with_ok?(url, username, password)
        require 'net/http'
        begin
          uri = URI(url)
          res = nil
          http = Net::HTTP.new(uri.hostname, uri.port)
          if url =~ /https\:/
            require 'net/https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          http.start do |h|
            request = Net::HTTP::Get.new(uri.request_uri)
            request.basic_auth username, password
            request['Accept'] = 'application/json'
            res = h.request(request)
            return true if res.code.to_s == '200'
          end
          Redfish.debug("GlassFish not responding OK - #{res.code} to #{url}")
        rescue Exception => e
          Redfish.info("Error while accessing GlassFish web interface at #{url}: #{e}")
          Redfish.debug(e.message)
          Redfish.debug(e.backtrace.join("\n"))
          return false
        end
      end
    end
  end
end
