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
  class Context
    # The directory in which glassfish has been installed.
    attr_reader :install_dir

    # The name of the domain.
    attr_reader :domain_name
    # The port on which the management application is bound.
    attr_reader :domain_admin_port
    # If true use SSL when communicating with the domain for administration. Assumes the domain is in secure mode.
    attr_reader :domain_secure
    # The username to use when communicating with the domain.
    attr_reader :domain_username
    # The password to use when communicating with the domain.
    attr_reader :domain_password
    # The password to use when accessing keystore.
    attr_reader :domain_master_password

    # Use terse output from the underlying asadmin.
    def terse?
      !!@terse
    end

    #If true, echo commands supplied to asadmin.
    def echo?
      !!@echo
    end

    # The directory that contains the domains. If nil then assumes the default directory.
    attr_reader :domains_directory
    # The path to the authbind executable, if glassfish must run as a subprocess of authbind.
    attr_reader :authbind_executable
    # The user that the asadmin command executes as.
    attr_reader :system_user
    # The group that the asadmin command executes as.
    attr_reader :system_group

    def initialize(executor, install_dir, domain_name, domain_admin_port, domain_secure, domain_username, domain_password, options = {})
      @executor, @domain_name, @domain_admin_port, @domain_secure, @domain_username, @domain_password =
        executor, domain_name, domain_admin_port, domain_secure, domain_username, domain_password

      @install_dir = install_dir[-1] == '/' ? install_dir[0...-1] : install_dir
      domains_directory = options[:domains_directory]
      if domains_directory
        @domains_directory = domains_directory[-1] == '/' ? domains_directory[0...-1] : domains_directory
      end

      @file_map = {}
      (options[:file_map] || {}).each_pair do |key, path|
        file(key, path)
      end

      @volume_map = {}
      (options[:volume_map] || {}).each_pair do |key, path|
        volume(key, path)
      end

      @echo = options[:echo].nil? ? false : !!options[:echo]
      @terse = options[:terse].nil? ? false : !!options[:terse]
      @system_user = options[:system_user]
      @system_group = options[:system_group]
      @authbind_executable = options[:authbind_executable]
      @property_cache = nil
      @restart_required = false
      @domain_started = false
      @domain_master_password = options[:domain_master_password] || @domain_password || Redfish::Util.generate_password
    end

    def task_group
      'glassfish'
    end

    def file(key, local_path)
      raise "File with key '#{key.to_s}' is associated with local file '#{@file_map[key.to_s]}', can not associate with '#{local_path}'" if @file_map[key.to_s]
      @file_map[key.to_s] = local_path
    end

    def file_map
      @file_map.dup
    end

    def volume(key, local_path)
      raise "Volume with key '#{key.to_s}' is associated with directory '#{@volume_map[key.to_s]}', can not associate with '#{local_path}'" if @volume_map[key.to_s]
      @volume_map[key.to_s] = local_path
    end

    def volume_map
      @volume_map.dup
    end

    # Directory of specific domain context is referencing
    def domain_directory
      top_level_directory = self.domains_directory.nil? ? "#{self.install_dir}/glassfish/domains" : self.domains_directory
      "#{top_level_directory}/#{self.domain_name}"
    end

    # The password file used when connecting to glassfish. Assume it is located inside domain in standard location if at all.
    def domain_password_file
      password_file = domain_password_file_location
      File.exist?(password_file) ? password_file : nil
    end

    def domain_password_file_location
      "#{domain_directory}/config/redfish.password"
    end

    def domain_started!
      @domain_started = true
    end

    def domain_started?
      @domain_started
    end

    def restart_required?
      !!@restart_required
    end

    def require_restart!
      @restart_required = true
    end

    def domain_restarted!
      @restart_required = false
    end

    def property_cache?
      !@property_cache.nil?
    end

    def property_cache
      raise 'Property cache not defined' unless property_cache?
      @property_cache
    end

    def domain_version(version = nil)
      version ||= property_cache['domain.version']
      Redfish::VersionManager.version_by_version_key(version)
    end

    def cache_properties(properties)
      raise 'Property cache already defined' if property_cache?
      @property_cache = PropertyCache.new(properties)
    end

    def remove_property_cache
      raise 'No property cache to remove' unless property_cache?
      @property_cache = nil
    end

    def exec(asadmin_command, args = [], options = {})
      @executor.exec(self, asadmin_command, args, options)
    end

    def build_command(asadmin_command, args = [], options = {})
      @executor.build_command(self, asadmin_command, args, options)
    end
  end
end
