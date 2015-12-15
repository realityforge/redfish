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
    # The password file used when connecting to glassfish.
    attr_reader :domain_password_file

    # Use terse output from the underlying asadmin.
    def terse?
      !!@terse
    end

    #If true, echo commands supplied to asadmin.
    def echo?
      !!@echo
    end

    # The user that the asadmin command executes as.
    attr_reader :system_user
    # The group that the asadmin command executes as.
    attr_reader :system_group

    def initialize(executor, install_dir, domain_name, domain_admin_port, domain_secure, domain_username, domain_password_file, options = {})
      @executor, @install_dir, @domain_name, @domain_admin_port, @domain_secure, @domain_username, @domain_password_file =
        executor, install_dir, domain_name, domain_admin_port, domain_secure, domain_username, domain_password_file
      @echo = options[:echo].nil? ? false : !!options[:echo]
      @terse = options[:terse].nil? ? false : !!options[:terse]
      @system_user = options[:system_user]
      @system_group = options[:system_group]
      @property_cache = nil
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
      return {:variant => 'Payara', :version => '4.1.152'} if '#badassfish-b187' == version
      return {:variant => 'Payara', :version => '4.1.1.154'} if '270' == version
      raise "Unknown domain.version #{version}"
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
  end
end
