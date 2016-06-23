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
      class LogLevels < AsadminTask
        private

        attribute :levels, :kind_of => Hash, :required => true, :custom_validation => true
        attribute :default_levels, :type => :boolean, :default => true

        def validate_levels(levels)
          levels.each_pair do |key, value|
            unless %w(SEVERE WARNING INFO CONFIG FINE FINER FINEST ALL OFF).include?(value)
              raise "Log level '#{key}' has an unknown level #{value}"
            end
          end
        end

        action :set do
          existing = current_levels
          levels_to_update = {}

          expected_levels.each_pair do |key, level|
            levels_to_update[key] = level unless existing[key] == level
          end

          unless levels_to_update.empty?
            args = []
            args << levels_to_update.collect { |k, v| "#{k}=#{v}" }.join(':')

            context.exec('set-log-levels', args)

            default_logging = "#{context.domain_directory}/config/default-logging.properties"
            FileUtils.cp "#{context.domain_directory}/config/logging.properties", default_logging
            FileUtils.chmod 0600, default_logging
            FileUtils.chown context.system_user, context.system_group, default_logging if context.system_user || context.system_group

            updated_by_last_action
          end
        end

        def instance_key
          "default_levels=#{self.default_levels}, levels='#{self.levels.collect { |k, v| "#{k}=#{v}" }.join(',')}'"
        end

        def current_levels
          output = context.exec('list-log-levels', [], :terse => true, :echo => false).gsub("[\n]+\n", "\n").split("\n").sort

          current_levels = {}
          output.each do |line|
            key, value = line.split
            next unless key
            # Remove <> brackets around level
            current_levels[key] = value[1, value.size - 2]
          end
          current_levels
        end

        def expected_levels
          (self.default_levels ? self.domain_version.default_log_levels : {}).merge(self.levels)
        end
      end
    end
  end
end
