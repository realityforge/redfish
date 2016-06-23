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
      class JvmOptions < AsadminTask
        private

        attribute :jvm_options, :kind_of => Array, :default => []
        attribute :defines, :kind_of => Hash, :default => {}
        attribute :default_defines, :type => :boolean, :default => true

        action :set do
          existing = current_options
          expected = expected_options

          todelete = existing - expected
          tocreate = expected - existing

          if !todelete.empty? || !tocreate.empty?
            context.exec('delete-jvm-options', [encode_options(todelete)]) unless todelete.empty?
            context.exec('create-jvm-options', [encode_options(tocreate)]) unless tocreate.empty?

            reload_property('configs.config.server-config.java-config.jvm-options') if context.property_cache?

            updated_by_last_action
          end
        end

        def encode_options(existing)
          existing.collect { |t| t.gsub(':', '\\:') }.join(':')
        end

        def instance_key
          "default_defines=#{default_defines} options=#{jvm_options.inspect} defines=#{defines.inspect}"
        end

        def expected_options
          options = []

          # Add defines in sorted order
          defines = derive_complete_defines
          defines.keys.sort.each do |key|
            options << "-D#{key}=#{defines[key]}"
          end

          options.concat(self.jvm_options)

          options
        end

        def derive_complete_defines
          defines = self.defines.dup
          if self.default_defines
            defines.merge!(self.domain_version.default_jvm_defines)
          end
          defines.merge!(self.defines)
          defines
        end

        def current_options
          context.exec('list-jvm-options', [], :terse => true, :echo => false).split("\n")
        end
      end
    end
  end
end
