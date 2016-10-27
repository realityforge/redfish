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
  class DomainDefinition
    def add_pre_artifacts(*artifacts)
      ::Buildr.artifacts(artifacts).each do |a|
        self.pre_artifacts << a.to_s
        Rake::Task.define_task("#{self.task_prefix}:pre_build" => [a.to_s])
      end
    end

    def add_post_artifacts(*artifacts)
      ::Buildr.artifacts(artifacts).each do |a|
        self.post_artifacts << a.to_s
        Rake::Task.define_task("#{self.task_prefix}:pre_build" => [a.to_s])
      end
    end

    def resolve_file(filename)
      Rake::FileTask.define_task(filename).invoke unless File.exist?(filename)
      filename
    end
  end

  class Buildr
    class Listener
      def on_task_start(execution_record)
        trace("Redfish Task #{execution_record} starting")
      end

      def on_task_complete(execution_record)
        if execution_record.action_performed_update? && is_task_interesting?(execution_record)
          info("Redfish Task #{execution_record} performed action")
        else
          trace("Redfish Task #{execution_record} completed")
        end
      end

      def on_task_error(execution_record)
        info("Redfish Task #{execution_record} resulted in error")
      end

      def is_task_interesting?(execution_record)
        return false if execution_record.action == :ensure_active && execution_record.task.class.registered_name == 'domain'
        return false if execution_record.action == :create && execution_record.task.class.registered_name == 'property_cache'
        return false if execution_record.action == :destroy && execution_record.task.class.registered_name == 'property_cache'
        true
      end
    end

    def self.define_tasks_for_domains
      Redfish.domains.each do |domain|
        next unless domain.enable_rake_integration?
        define_tasks_for_domain(domain)
      end
    end

    def self.define_tasks_for_domain(domain)
      raise "Attempted to define rake tasks for #{domain.name} which has disabled rake integration" unless domain.enable_rake_integration?

      task "#{domain.task_prefix}:config"

      task "#{domain.task_prefix}:pre_build" => ["#{domain.task_prefix}:config"] do
        domain.volume_map.values.each do |volume|
          FileUtils.mkdir_p volume
        end
      end

      if domain.complete? && domain.local?
        desc "Configure a local GlassFish instance based on '#{domain.name}' domain definition with key '#{domain.key}'"
        task "#{domain.task_prefix}:create" => ["#{domain.task_prefix}:pre_build"] do
          Redfish::Driver.configure_domain(domain, :listeners => [Listener.new])
        end

        desc "Update a local GlassFish instance based on '#{domain.name}' domain definition with key '#{domain.key}'"
        task "#{domain.task_prefix}:update" => ["#{domain.task_prefix}:pre_build"] do
          Redfish::Driver.configure_domain(domain, :listeners => [Listener.new], :update_only => true)
        end
      end

      if domain.dockerize?
        directory = "#{Redfish::Config.base_directory}/generated/redfish/docker/#{domain.key}"
        desc "Setup a directory containing docker configuration for GlassFish instance based on '#{domain.name}' domain definition with key '#{domain.key}'"
        task "#{domain.task_prefix}:docker:setup" => ["#{domain.task_prefix}:pre_build"] do
          info("Configuring docker directory for '#{domain.name}' domain with key '#{domain.key}' at #{directory}")
          domain.setup_docker_dir(directory)
        end

        desc "Build a docker image for GlassFish instance based on '#{domain.name}' domain definition with key '#{domain.key}'"
        task "#{domain.task_prefix}:docker:build" => ["#{domain.task_prefix}:docker:setup"] do
          if `docker images --format "{{.ID}}" #{domain.labels.collect { |k, v| "--filter label=#{k}=#{v}" }.join(' ') }`.empty?
            info("Building docker image for '#{domain.name}' domain with key '#{domain.key}' as #{domain.image_name}")
            command = domain.docker_build_command(directory)
            sh(command)
          end
        end

        desc "Run a container based on the docker image for GlassFish instance based on '#{domain.name}' domain definition with key '#{domain.key}'"
        task "#{domain.task_prefix}:docker:run" => ["#{domain.task_prefix}:docker:build"] do
          info("Running docker image for '#{domain.name}' domain with key '#{domain.key}' as #{domain.image_name}")
          domain.volume_map.values.each do |volume|
            FileUtils.mkdir_p volume
          end
          command = "#{domain.docker_run_command} #{ENV['DOCKER_ARGS']}"
          puts(command) if ::Buildr.application.options.trace
          exec(command)
        end

        desc "Print command to run a container based on the docker image for GlassFish instance based on '#{domain.name}' domain definition with key '#{domain.key}'"
        task "#{domain.task_prefix}:docker:print_run" => ["#{domain.task_prefix}:config"] do
          command = "#{domain.docker_run_command} #{ENV['DOCKER_ARGS']}"
          puts(command)
        end

        desc "Remove docker image for GlassFish instance based on '#{domain.name}' domain definition with key '#{domain.key}'"
        task "#{domain.task_prefix}:docker:rm" do
          unless `docker images -q #{domain.image_name}`.empty?
            sh("docker rmi $(docker images -q #{domain.image_name})")
          end
        end

        desc "Remove all docker docker images for GlassFish instance based on '#{domain.name}' domain definition with key '#{domain.key}'"
        task "#{domain.task_prefix}:docker:rm_all" do
          unless `docker images -q #{domain.name}`.empty?
            sh("docker rmi $(docker images -q #{domain.name})")
          end
        end
      end

      desc "Export GlassFish configation based on #{domain.name} domain definition"
      task "#{domain.task_prefix}:export" => ["#{domain.task_prefix}:pre_build"] do
        filename = "#{Redfish::Config.base_directory}/generated/redfish/definitions/#{domain.key}.json"
        info("Exporting '#{domain.name}' domain with key '#{domain.key}' to #{filename}")
        domain.export_to_file(filename, :expand => domain.complete?, :checkpointed_data => !domain.complete?)
      end
    end

    def self.define_domain_packages(options = {})
      buildr_project = get_buildr_project('generating domain packages', options)

      Redfish.domains.each do |domain|
        next unless domain.package?
        buildr_project.instance_eval do
          project.define(domain.name) do
            project.no_iml
            Redfish::Buildr.define_domain_package(domain.name, options)
          end
        end
      end
    end

    def self.define_domain_package(domain_name, options = {})
      domain = Redfish.domain_by_key(domain_name)
      raise "Unable to define package for domain '#{domain.key}' as package = false" unless domain.package?

      buildr_project = get_buildr_project("generating #{domain_name} domain package", options)
      buildr_project.package(:json).enhance(["#{domain.task_prefix}:pre_build"]) do |t|
        domain.export_to_file(t.to_s, :checkpointed_data => true)
      end
    end

    def self.get_buildr_project(reason, options = {})
      buildr_project = options[:buildr_project]
      if buildr_project.nil? && ::Buildr.application.current_scope.size > 0
        buildr_project = ::Buildr.project(::Buildr.application.current_scope.join(':')) rescue nil
      end
      raise "Unable to determine Buildr project when #{reason}" unless buildr_project
      buildr_project
    end
  end
end

if Redfish::Util.is_buildr_present?
  class Buildr::Project
    def package_as_json(file_name)
      file(file_name)
    end
  end
end
