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
  class DomainDefinition < BaseElement
    def initialize(key, options = {}, &block)
      options = options.dup
      @key = key
      @name = key
      @data = Redfish::Mash.new
      @version = nil
      @file_map = {}
      @secure = true
      @echo = false
      @terse = false
      @packaged = false
      @package = true
      @complete = true
      @rake_integration = true
      @admin_port = 4848
      @admin_username = 'admin'
      @admin_password = Redfish::Util.generate_password
      @admin_password_random = true
      @glassfish_home = nil
      @domains_directory = nil
      @ports = []
      @environment_vars = {}
      @pre_artifacts = []
      @post_artifacts = []
      @authbind_executable = nil
      @system_user = nil
      @system_group = nil
      @file_map = {}
      (options.delete(:file_map) || {}).each_pair do |key, path|
        file(key, path)
      end

      options = options.dup
      @extends = options.delete(:extends)
      if @extends
        parent = Redfish.domain_by_key(@extends)
        @name = parent.name
        @secure = parent.secure?
        @echo = parent.echo?
        @terse = parent.terse?
        @ports = parent.ports.dup
        @environment_vars = parent.environment_vars.dup
        @admin_port = parent.admin_port
        @admin_username = parent.admin_username
        @admin_password = parent.admin_password
        @admin_password_random = parent.admin_password_random?
        @master_password = parent.master_password
        @glassfish_home = parent.glassfish_home
        @domains_directory = parent.domains_directory
        @authbind_executable = parent.authbind_executable
        @system_user = parent.system_user
        @system_group = parent.system_group
        parent.file_map.each_pair do |key, path|
          file(key, path)
        end
        # Deliberately do not copy @packaged, @package, @complete, @pre_artifacts, @post_artifacts, @rake_integration
      end
      super(options, &block)
    end

    attr_reader :key
    attr_reader :name
    attr_reader :extends
    attr_reader :data
    attr_accessor :version

    def package?
      !!@package
    end

    attr_writer :package

    # If true then this domain definition is not complete and can not be converged or converted into a docker image.
    def complete?
      !!@complete
    end

    attr_writer :complete

    # If true use SSL when communicating with the domain for administration. Assumes the domain is in secure mode.
    def secure?
      !!@secure
    end

    attr_writer :secure
    attr_accessor :admin_port
    # The username to use when communicating with the domain.
    attr_accessor :admin_username
    # The password to use when communicating with the domain.
    attr_reader :admin_password
    # The password to use when accessing keystore.
    attr_accessor :master_password

    # An array of ports that will are accessible from the domain
    attr_accessor :ports

    def admin_password=(admin_password)
      @admin_password_random = false
      @admin_password = admin_password
    end

    def admin_password_random?
      !!@admin_password_random
    end

    def glassfish_home
      @glassfish_home || Redfish::Config.default_glassfish_home
    end

    attr_writer :glassfish_home

    # The directory that contains the domains. If nil then assumes the default directory.
    def domains_directory
      @domains_directory || Redfish::Config.default_domains_directory
    end

    attr_writer :domains_directory
    # The path to the authbind executable, if glassfish must run as a subprocess of authbind.
    attr_accessor :authbind_executable
    # The user that the asadmin command executes as.
    attr_accessor :system_user
    # The group that the asadmin command executes as.
    attr_accessor :system_group

    # A map of environment variables expected to be passed into the docker instance. Maps keys to default values.
    attr_reader :environment_vars

    # Use terse output from the underlying asadmin.
    def terse?
      !!@terse
    end

    attr_writer :terse

    #If true, echo commands supplied to asadmin.
    def echo?
      !!@echo
    end

    attr_writer :echo

    attr_writer :rake_integration

    def enable_rake_integration?
      @rake_integration.nil? ? true : @rake_integration
    end

    attr_writer :packaged

    def packaged?
      @packaged.nil? ? false : @packaged
    end

    def task_prefix
      raise 'task_prefix invoked' unless enable_rake_integration? || packaged?
      "#{Redfish::Config.task_prefix}:domain#{Redfish::Config.default_domain_key?(self.key) ? '' : ":#{self.key}"}"
    end

    attr_reader :pre_artifacts
    attr_reader :post_artifacts

    def file(key, local_path)
      raise "File with key '#{key.to_s}' is associated with local file '#{@file_map[key.to_s]}', can not associate with '#{local_path}'" if @file_map[key.to_s]
      @file_map[key.to_s] = local_path
    end

    def file_map
      @file_map.dup
    end

    def resolved_data
      data = Redfish::Mash.new
      data.merge!(Redfish.domain_by_key(self.extends).resolved_data) if self.extends
      self.pre_artifacts.each do |filename|
        data.merge!(JSON.load(File.new(filename)))
      end
      data.merge!(self.data)
      self.post_artifacts.each do |filename|
        data.merge!(JSON.load(File.new(filename)))
      end
      data.sort
    end

    def to_task_context(executor = Redfish::Executor.new)
      Redfish::Context.new(executor,
                           self.glassfish_home,
                           self.name,
                           self.admin_port,
                           self.secure?,
                           self.admin_username,
                           self.admin_password,
                           {
                             :terse => self.terse?,
                             :echo => self.echo?,
                             :domain_master_password => self.master_password,
                             :system_user => self.system_user,
                             :system_group => self.system_group,
                             :authbind_executable => self.authbind_executable,
                             :file_map => self.file_map,
                             :domains_directory => self.domains_directory
                           })
    end

    def export_to_file(filename)
      dir = File.dirname(filename)
      FileUtils.mkdir_p dir
      File.open(filename, 'wb') do |f|
        f.write JSON.pretty_generate(self.resolved_data)
      end
    end
  end
end
