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
    class LogAttributes < AsadminTask
      private

      attribute :attributes, :kind_of => Hash, :required => true

      action :set do
        existing = current_attributes
        attributes_to_update = {}

        self.attributes.each_pair do |key, level|
          attributes_to_update[key] = level unless existing[key] == level
        end

        unless attributes_to_update.empty?
          args = []
          # TODO: Set payara specific arg here if use one of the non-standard args
          args << self.attributes.collect{|k,v| "#{k}=#{v}"}.join(':')

          context.exec('set-log-attributes', args)

          updated_by_last_action
        end
      end

      def instance_key
        self.attributes.collect{|k,v| "#{k}=#{v}"}.join(',')
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
    end
  end
end
