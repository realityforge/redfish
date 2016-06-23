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
      class LogAttributes < AsadminTask
        private

        attribute :attributes, :kind_of => Hash, :required => true
        attribute :default_attributes, :type => :boolean, :default => true

        action :set do
          existing = current_attributes
          attributes_to_update = {}

          attr = expected_attributes
          attr.each_pair do |key, level|
            attributes_to_update[key] = level unless existing[key] == level
          end

          unless attributes_to_update.empty?
            args = []

            if self.domain_version.payara? && attr.keys.any? { |a| !standard_attributes.include?(a.to_s) }
              args << '--validate=false'
            end

            args << attr.collect { |k, v| "#{k}=#{v}" }.join(':')

            context.exec('set-log-attributes', args)

            default_logging = "#{context.domain_directory}/config/default-logging.properties"
            FileUtils.cp "#{context.domain_directory}/config/logging.properties", default_logging
            FileUtils.chmod 0600, default_logging
            FileUtils.chown context.system_user, context.system_group, default_logging if context.system_user || context.system_group

            updated_by_last_action
          end
        end

        def instance_key
          "default_attributes=#{self.default_attributes}, attributes='#{self.attributes.collect { |k, v| "#{k}=#{v}" }.join(',')}'"
        end

        def current_attributes
          output = context.exec('list-log-attributes', [], :terse => true, :echo => false).gsub("[\n]+\n", "\n").split("\n").sort

          current_attributes = {}
          output.each do |line|
            key, value = line.split
            next unless key
            # Remove <> brackets around attribute
            current_attributes[key] = value[1, value.size - 2]
          end
          current_attributes
        end

        def expected_attributes
          (self.default_attributes ? self.domain_version.default_log_attributes : {}).merge(self.attributes)
        end

        # The set of attributes that the non-payara asadmin can modify
        def standard_attributes
          %w(
          com.sun.enterprise.server.logging.GFFileHandler.alarms
          com.sun.enterprise.server.logging.GFFileHandler.file
          com.sun.enterprise.server.logging.GFFileHandler.flushFrequency
          com.sun.enterprise.server.logging.GFFileHandler.formatter
          com.sun.enterprise.server.logging.GFFileHandler.logtoConsole
          com.sun.enterprise.server.logging.GFFileHandler.maxHistoryFiles
          com.sun.enterprise.server.logging.GFFileHandler.retainErrorsStasticsForHours
          com.sun.enterprise.server.logging.GFFileHandler.rotationLimitInBytes
          com.sun.enterprise.server.logging.GFFileHandler.rotationTimelimitInMinutes
          com.sun.enterprise.server.logging.SyslogHandler.useSystemLogging
          handlers
          java.util.logging.ConsoleHandler.formatter
          java.util.logging.FileHandler.count
          java.util.logging.FileHandler.formatter
          java.util.logging.FileHandler.limit
          java.util.logging.FileHandler.pattern
          log4j.logger.org.hibernate.validator.util.Version
        )
        end
      end
    end
  end
end
