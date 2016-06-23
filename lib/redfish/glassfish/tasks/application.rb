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
      class Application < BaseResourceTask
        PROPERTY_PREFIX = 'applications.application.'

        TYPES = %w(car ear ejb osgi rar war)

        private

        attribute :name, :kind_of => String, :required => true, :identity_field => true
        attribute :location, :kind_of => String, :default => nil
        attribute :deployment_plan, :kind_of => String, :default => nil
        attribute :context_root, :kind_of => String, :default => nil
        attribute :virtual_servers, :kind_of => Array, :default => []
        attribute :enabled, :type => :boolean, :default => true
        attribute :type, :equal_to => TYPES + TYPES.collect { |a| a.to_sym } + [nil], :default => nil

        attribute :generate_rmi_stubs, :type => :boolean, :default => false
        attribute :availability_enabled, :type => :boolean, :default => false
        attribute :lb_enabled, :type => :boolean, :default => true
        attribute :keep_state, :type => :boolean, :default => false
        attribute :verify, :type => :boolean, :default => false
        attribute :precompile_jsp, :type => :boolean, :default => true
        attribute :async_replication, :type => :boolean, :default => true

        attribute :properties, :kind_of => Hash, :default => {}
        attribute :deployment_order, :kind_of => Fixnum, :default => 100

        action :create do
          @path = nil
          create(resource_property_prefix)
        end

        action :destroy do
          destroy(resource_property_prefix)
        end

        def resource_property_prefix
          "#{PROPERTY_PREFIX}#{self.name}."
        end

        def properties_to_record_in_create
          {'object-type' => 'user', 'name' => self.name, 'deployment-order' => '100'}
        end

        def properties_to_set_in_create
          property_map = {}

          collect_property_sets(resource_property_prefix, property_map)

          property_map['enabled'] = self.enabled
          property_map['async-replication'] = self.async_replication
          property_map['availability-enabled'] = self.availability_enabled
          property_map['directory-deployed'] = is_location_a_directory?
          property_map['context-root'] = self.context_root.nil? ? '' : self.context_root
          property_map['location'] = is_location_a_directory? ? "file:#{resolved_location.gsub(/\/$/, '')}/" : "${com.sun.aas.instanceRootURI}/applications/#{self.name}/"

          property_map['property.defaultAppName'] = File.basename(self.location, File.extname(self.location))
          property_map['property.archiveType'] = derive_archive_type
          property_map['property.appLocation'] = is_location_a_directory? ? "file:#{resolved_location.gsub(/\/$/, '')}/" : "${com.sun.aas.instanceRootURI}/applications/__internal/#{self.name}/#{File.basename(self.location)}"

          property_map
        end

        def is_location_a_directory?
          File.directory?(resolved_location)
        end

        def derive_archive_type
          return self.type unless type.nil?
          unless is_location_a_directory?
            extension = File.extname(resolved_location.to_s)
            unless extension.empty?
              type = extension[1..-1]
              return type if TYPES.include?(type)
            end
          end
          'war'
        end

        def resolved_location
          unless @path
            raise 'The "location" parameter must be set when deploying application.' if self.location.nil?
            @path = File.expand_path(self.location)
            raise 'The "location" must reference a archive or directory that exists when deploying application.' unless File.exist?(@path)
          end
          @path
        end

        def do_create

          args = []
          args << '--name' << self.name.to_s
          args << "--enabled=#{self.enabled}"
          args << '--force=true'
          args << '--type' << derive_archive_type
          args << "--contextroot=#{self.context_root}" if self.context_root
          args << "--generatermistubs=#{self.generate_rmi_stubs}"
          args << "--availabilityenabled=#{self.availability_enabled}"
          args << "--lbenabled=#{self.lb_enabled}"
          args << "--keepstate=#{self.keep_state}"
          args << "--verify=#{self.verify}"
          args << "--precompilejsp=#{self.precompile_jsp}"
          args << "--asyncreplication=#{self.async_replication}"
          args << "--virtualservers=#{self.virtual_servers.join(',')}" unless self.virtual_servers.empty?
          args << '--deploymentplan' << self.deployment_plan.to_s if self.deployment_plan
          args << '--deploymentorder' << self.deployment_order.to_s
          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << resolved_location.to_s

          output = context.exec(is_location_a_directory? ? 'deploydir' : 'deploy', args)
          if output =~ /Command deploy failed./ || !(output =~ /Command deploy executed successfully\./)
            raise "Failed to deploy application #{self.name}. Output follows:\n#{output}"
          end
        end

        def post_create_hook
          if context.property_cache?
            reload_properties_with_prefix("applications.application.#{self.name}.property.org.glassfish.")
            reload_properties_with_prefix("applications.application.#{self.name}.module.")
          end
        end

        def do_destroy
          context.exec('undeploy', ["--cascade=#{self.type == 'rar'}", self.name])
        end

        def record_reference
          prefix = "servers.server.server.application-ref.#{resource_name}."
          servers = self.virtual_servers.empty? ? 'server' : self.virtual_servers.join(',')
          record_properties_in_cache('',
                                     "#{prefix}enabled" => self.enabled,
                                     "#{prefix}lb-enabled" => self.lb_enabled,
                                     "#{prefix}virtual-servers" => servers,
                                     "#{prefix}disable-timeout-in-minutes" => '30',
                                     "#{prefix}ref" => resource_name)
        end

        def remove_reference
          context.property_cache.delete_all_with_prefix!("servers.server.server.application-ref.#{resource_name}.")
        end

        def present?
          (context.exec('list-applications', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)} +\</)
        end
      end
    end
  end
end
