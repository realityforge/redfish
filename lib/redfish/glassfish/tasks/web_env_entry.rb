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
      class WebEnvEntry < BaseResourceTask
        private

        # The name of the associated application.
        attribute :application, :kind_of => String, :required => true, :identity_field => true
        # The optional name of the module if part of multiple module application.
        attribute :module, :kind_of => [String, NilClass]
        # The key name of the web env entry.
        attribute :name, :kind_of => String, :required => true, :identity_field => true
        # The java type name of env entry.
        attribute :type, :equal_to => %w(java.lang.Boolean java.lang.Byte java.lang.Character java.lang.Double java.lang.Float java.lang.Integer java.lang.Long java.lang.Short java.lang.String), :default => 'java.lang.String'
        # The value of the entry.
        attribute :value, :kind_of => String
        # Specifies whether the environment entry is ignored if it is set in the application's deployment descriptor. When an environment entry is ignored, the application behaves as if the entry had never been set in the application's deployment descriptor.
        attribute :ignore_descriptor_item, :type => :boolean, :default => false
        # A description of the entry.
        attribute :description, :kind_of => String

        action :create do
          raise 'At least one of the "ignore_descriptor_item" or "value" parameters must be set.' if !ignore_descriptor_item? && self.value.nil?
          raise 'Only one of "ignore_descriptor_item" or "value" parameters must be set but both are specified.' if ignore_descriptor_item? && !self.value.nil?
          create(resource_property_prefix)
        end

        action :destroy do
          destroy(resource_property_prefix)
        end

        def ignore_descriptor_item?
          self.ignore_descriptor_item.to_s == 'true'
        end

        def resource_property_prefix
          "applications.application.#{self.application}.module.#{self.module.nil? ? self.application : self.module}.engine.web.web-module-config.env-entry.#{self.name}."
        end

        def properties_to_record_in_create
          {'env-entry-name' => self.name}
        end

        def properties_to_set_in_create
          property_map = {}

          property_map['description'] = self.description
          property_map['env-entry-type'] = ignore_descriptor_item? ? '' : self.type
          property_map['env-entry-value'] = ignore_descriptor_item? ? '' : self.value
          property_map['ignore-descriptor-item'] = self.ignore_descriptor_item

          property_map
        end

        def do_create
          args = []

          args << '--name' << self.name.to_s
          args << '--type' << self.type.to_s unless ignore_descriptor_item?
          args << '--description' << self.description.to_s
          args << '--value' << self.value.to_s unless self.value.nil?
          args << "--ignoreDescriptorItem=#{self.ignore_descriptor_item}"
          args << application_spec

          context.exec('set-web-env-entry', args)
        end

        def application_spec
          "#{self.application.to_s}#{self.module.nil? ? '' : "/#{self.module}"}"
        end

        def do_destroy
          context.exec('unset-web-env-entry', ['--name', self.name, application_spec])
        end

        def add_resource_ref?
          false
        end

        def present?
          (context.exec('list-web-env-entry', [application_spec], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)} (#{Regexp.escape('(java.lang.')}|#{Regexp.escape('(null)')})/)
        end
      end
    end
  end
end
