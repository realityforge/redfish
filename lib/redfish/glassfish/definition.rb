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
  class DomainDefinition < Reality::BaseElement
    def initialize(key, options = {}, &block)
      options = options.dup
      @key = key
      @name = key
      @data = Reality::Mash.new
      checkpoint_data!
      @version = nil
      @file_map = {}
      @volume_map = {}
      @secure = true
      @local = true
      @echo = false
      @terse = false
      @packaged = false
      @dockerize = false
      @package = true
      @complete = true
      @rake_integration = true
      @admin_port = 4848
      @admin_username = 'admin'
      @base_image_name = 'stocksoftware/redfish:latest'
      @admin_password = Redfish::Util.generate_password
      @admin_password_random = true
      @glassfish_home = nil
      @domains_directory = nil
      @ports = []
      @pre_artifacts = []
      @post_artifacts = []
      @authbind_executable = nil
      @system_user = nil
      @system_group = nil
      @file_map = {}
      (options.delete(:file_map) || {}).each_pair do |file_key, path|
        file(file_key, path)
      end
      (options.delete(:volume_map) || {}).each_pair do |volume_key, path|
        volume(volume_key, path)
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
        @admin_port = parent.admin_port
        @admin_username = parent.admin_username
        @admin_password = parent.admin_password
        @admin_password_random = parent.admin_password_random?
        @master_password = parent.master_password
        @glassfish_home = parent.glassfish_home if parent.glassfish_home_defined?
        @domains_directory = parent.domains_directory if parent.domains_directory_defined?
        @authbind_executable = parent.authbind_executable
        @system_user = parent.system_user
        @system_group = parent.system_group
        parent.file_map.each_pair do |file_key, path|
          file(file_key, path)
        end
        parent.volume_map.each_pair do |volume_key, path|
          volume(volume_key, path)
        end
        # Deliberately do not copy @packaged, @package, @complete, @pre_artifacts, @post_artifacts, @rake_integration
      end
      super(options, &block)
    end

    attr_reader :key
    attr_reader :name
    attr_reader :extends
    attr_reader :data
    # Data as it was represented last time the checkpoint method was called
    # Checkpointing typically occurs just before specific environmemnt configuration is added
    attr_reader :checkpointed_data
    attr_accessor :version

    def package?
      !!@package
    end

    attr_writer :package

    # If true then this domain definition is not complete and can not be converged or converted into a docker image.
    def complete?
      !!@complete
    end

    attr_writer :local

    def local?
      @local.nil? ? true : !!@local
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

    def glassfish_home_defined?
      !@glassfish_home.nil?
    end

    attr_writer :glassfish_home

    # The directory that contains the domains. If nil then assumes the default directory.
    def domains_directory
      @domains_directory || Redfish::Config.default_domains_directory
    end

    def domains_directory_defined?
      !@domains_directory.nil?
    end

    attr_writer :domains_directory
    # The path to the authbind executable, if glassfish must run as a subprocess of authbind.
    attr_accessor :authbind_executable
    # The user that the asadmin command executes as.
    attr_accessor :system_user
    # The group that the asadmin command executes as.
    attr_accessor :system_group

    # A helper to retrieve the set of environment variables expected to be passed into the docker instance.
    # Extracted from environment_vars key after resolving data attribute.
    def environment_vars
      self.resolved_data['environment_vars'].to_h
    end

    # A helper to retrieve the set of volumes expected to be defined.
    # Extracted from volumes key after resolving data attribute.
    def volume_requirements
      self.resolved_data['volumes'].to_h
    end

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

    attr_writer :dockerize

    def dockerize?
      @dockerize.nil? ? false : @dockerize
    end

    def base_image_name=(base_image_name)
      Redfish.error("base_image_name= invoked on domain #{self.name} which should not be dockerized") unless dockerize?
      @base_image_name = base_image_name
    end

    def base_image_name
      Redfish.error("base_image_name invoked on domain #{self.name} which should not be dockerized") unless dockerize?
      @base_image_name
    end

    def image_name
      Redfish.error("image_name invoked on domain #{self.name} which should not be dockerized") unless dockerize?
      "#{self.name}#{self.version.nil? ? '' : ":#{self.version}"}"
    end

    # Arguments passed to the docker command when attempting to run domain
    # Useful for setting environment variables etc.
    def docker_run_args
      @docker_run_args ||= []
    end

    # ip address of dns server to fallback to when non-local addresses used.
    attr_accessor :docker_dns

    def docker_build_command(directory, options = {})
      quiet_flag = !!options[:quiet] ? '-q ' : ''
      "docker build --pull #{quiet_flag}--rm=true -t #{self.image_name} #{directory}"
    end

    def docker_run_command
      dns_opt = self.docker_dns.nil? ? '' : " --dns=#{self.docker_dns}"
      args = self.docker_run_args.join(' ')
      volumes = self.volume_map.collect { |key, local_path| "--volume=#{local_path}:/srv/glassfish/volumes/#{key}" }.join(' ')
      env_vars = []
      self.environment_vars.each_pair do |key, value|
        env_vars << "--env=\"#{key}=#{value}\"" unless value.to_s == ''
      end
      "docker run -ti --rm -P#{dns_opt} #{env_vars.join(' ')}#{env_vars.empty? ? '' : ' '}#{volumes}#{volumes.empty? ? '' : ' '}--name #{self.name} #{args}#{args.empty? ? '' : ' '}#{self.image_name}"
    end

    def task_prefix
      raise 'task_prefix invoked' unless enable_rake_integration? || packaged? || dockerize?
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

    def volume(key, local_path)
      raise "Volume with key '#{key.to_s}' is associated with directory '#{@volume_map[key.to_s]}', can not associate with '#{local_path}'" if @volume_map[key.to_s]
      @volume_map[key.to_s] = local_path
    end

    def volume_map
      @volume_map.dup
    end

    def resolved_data(options = {})
      data = Reality::Mash.new
      data.merge!(Redfish.domain_by_key(self.extends).resolved_data) if self.extends
      self.pre_artifacts.each do |filename|
        data.merge!(JSON.load(File.new(resolve_file(filename))))
      end
      data.merge!(options[:checkpointed_data] ? self.checkpointed_data : self.data)
      self.post_artifacts.each do |filename|
        data.merge!(JSON.load(File.new(resolve_file(filename))))
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
                             :volume_map => self.volume_map,
                             :domains_directory => self.domains_directory
                           })
    end

    def additional_labels
      @additional_labels ||= {}
    end

    def labels
      {
        'org.realityforge.redfish.domain_name' => self.name.to_s,
        'org.realityforge.redfish.domain_version' => self.version.to_s,
        'org.realityforge.redfish.domain_hash' => self.version_hash.to_s
      }.merge(self.additional_labels)
    end

    def export_to_file(filename, options = {})
      data = self.resolved_data(:checkpointed_data => options[:checkpointed_data])
      if options[:expand]
        Redfish::Interpreter::PreInterpreter.pre_interpret(data)
        data = Redfish::Interpreter::Interpolater.interpolate(self.to_task_context, data.to_h)
      end

      dir = File.dirname(filename)
      FileUtils.mkdir_p dir
      File.open(filename, 'wb') do |f|
        f.write JSON.pretty_generate(data)
      end
    end

    def setup_docker_dir(dir)
      raise "Attempting to setup docker directory for domain with key #{self.key} when dockerize set to false" unless dockerize?
      FileUtils.rm_rf dir
      FileUtils.mkdir_p dir

      setup_docker_redfish_dir(dir)
      setup_dockerfile(dir)
      # This seems to be required for auxfs storage driver under Linux
      FileUtils.chmod_R 0644, Dir["#{dir}/**/*"].select { |f| !File.directory?(f) }
      FileUtils.chmod_R 0755, Dir["#{dir}/**/*"].select { |f| File.directory?(f) }
    end

    def version_hash
      calculate_version_hash
    end

    def checkpoint_data!
      @checkpointed_data = Reality::Mash.from(self.data.to_h)
    end

    private

    def calculate_version_hash
      data = self.resolved_data.to_h
      data['definition'] = {}
      [
        :key, :name, :extends, :version, :pre_artifacts, :post_artifacts, :secure?,
        :admin_port, :admin_username, :ports, :authbind_executable, :system_user, :system_group
      ].each do |key|
        data['definition'][key.to_s] = self.send(key)
      end
      data['definition']['domains_directory'] = self.domains_directory if self.domains_directory_defined?
      data['definition']['glassfish_home'] = self.glassfish_home if self.glassfish_home_defined?
      data['definition']['admin_password'] = self.admin_password unless self.admin_password_random?
      data['definition']['file_map'] = self.file_map.keys
      data['definition']['volume_map'] = self.volume_map.keys

      Digest::MD5.hexdigest(JSON.pretty_generate(data))
    end

    def setup_dockerfile(dir)
      # When the Dockerfile format improves we should be able to remove redfish from the image altogether
      File.open("#{dir}/Dockerfile", 'wb') do |f|
        volumes = self.volume_map.keys.collect { |key| "/srv/glassfish/volumes/#{key}" }.join(' ')
        f.write <<SCRIPT
FROM #{self.base_image_name}
USER root
COPY ./redfish /opt/redfish
RUN chmod -R a+r /opt/redfish && find /opt/redfish -type d -exec chmod a+x {} \\; && chmod a+x /opt/redfish/run
USER glassfish:glassfish
RUN mkdir -p /tmp/glassfish #{volumes}#{volumes.empty? ? '' : ' '}&& \\
    export TMPDIR=/tmp/glassfish && \\
    java -jar ${JRUBY_JAR} /opt/redfish/domain.rb && \\
    java -jar ${GLASSFISH_PATCHER_JAR} -f /srv/glassfish/domains/#{self.name}/config/domain.xml#{self.environment_vars.empty? ? '' : ' '}#{self.environment_vars.keys.collect { |k| "-s#{k}=@@#{k}@@" }.join(' ')} && \\
    rm -rf /tmp/glassfish /srv/glassfish/.gfclient /tmp/hsperfdata_glassfish /srv/glassfish/domains/#{self.name}/config/secure.marker

USER glassfish:glassfish
EXPOSE #{self.ports.join(' ')} #{self.admin_port}
CMD ["/opt/redfish/run"]
WORKDIR /srv/glassfish/domains/#{self.name}
SCRIPT
        unless volumes.empty?
          f.write <<SCRIPT
VOLUME #{volumes}
SCRIPT
        end
        if labels.size > 0
          f.write <<SCRIPT
LABEL #{self.labels.collect { |k, v| "#{k}=\"#{v}\"" }.join(" \\\n      ")}
SCRIPT
        end
      end
    end

    def setup_docker_redfish_dir(dir)
      FileUtils.mkdir_p "#{dir}/redfish/lib"
      FileUtils.cp_r File.expand_path(File.dirname(__FILE__) + '/../..') + '/.', "#{dir}/redfish/lib"

      spec = Gem::Specification::load(File.expand_path(File.dirname(__FILE__) + '/../../../redfish.gemspec'))
      spec.dependencies.select{|dependency| dependency.type == :runtime }.each do |dep|
        dep_spec = Gem.loaded_specs[dep.name]
        dep_spec.require_paths.each do |path|
          lib_path = dep_spec.gem_dir + '/' + path + '/.'
          FileUtils.cp_r lib_path, "#{dir}/redfish/lib"
        end
      end

      export_to_file("#{dir}/redfish/domain.json")
      write_redfish_script(dir)
      write_run_script(dir)
    end

    def write_run_script(dir)
      File.open("#{dir}/redfish/run", 'wb') do |f|
        f.write <<SCRIPT
#!/bin/bash

SCRIPT
        self.environment_vars.each_pair do |k, v|
          f.write <<SCRIPT
if [ "${#{k}:-#{v}}" = '' ]; then
  echo "Failed to supply environment data for #{k}"
  exit 1
fi
SCRIPT
        end
        f.write <<SCRIPT
java -jar ${GLASSFISH_PATCHER_JAR} -f /srv/glassfish/domains/#{self.name}/config/domain.xml#{self.environment_vars.empty? ? '' : ' '}#{self.environment_vars.collect { |k, v| "-s#{k}=${#{k}:-#{v}}" }.join(' ')} && \\
/srv/glassfish/domains/#{self.name}/bin/asadmin_run
SCRIPT
      end
    end

    def write_redfish_script(dir)
      File.open("#{dir}/redfish/domain.rb", 'wb') do |f|
        f.write <<SCRIPT
CURRENT_DIR = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << File.expand_path("\#{CURRENT_DIR}/lib")
require 'redfish_plus'

domain = Redfish.domain('#{self.name}') do |domain|
  domain.pre_artifacts << "\#{CURRENT_DIR}/domain.json"
SCRIPT
        self.file_map.each_pair do |key, path|
          short_name = File.basename(path)
          docker_cache_path = "#{dir}/redfish/files/#{key}"
          FileUtils.mkdir_p docker_cache_path
          if File.directory?(path)
            FileUtils.cp_r path, docker_cache_path
          else
            FileUtils.cp path, docker_cache_path
          end
          f.write "  domain.file('#{key}', '/opt/redfish/files/#{key}/#{short_name}')\n"
        end
        self.volume_map.keys.each do |key|
          f.write "  domain.volume('#{key}', '/srv/glassfish/volumes/#{key}')\n"
        end
        f.write <<SCRIPT
end

Redfish::Driver.configure_domain(domain, :listeners => [Redfish::BasicListener.new])
SCRIPT
      end
    end
  end
end
