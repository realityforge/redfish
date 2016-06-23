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
      class RealmTypes < AsadminTask
        private

        attribute :realm_types, :kind_of => Hash, :required => true
        attribute :default_realm_types, :type => :boolean, :default => true

        action :set do
          text = as_text

          filename = "#{context.domain_directory}/config/login.conf"

          contents = IO.read(filename)

          if contents != text
            File.open(filename, 'wb') do |f|
              f.write text
            end

            FileUtils.chmod 0600, filename
            FileUtils.chown context.system_user, context.system_group, filename if context.system_user || context.system_group

            context.require_restart!

            updated_by_last_action
          end

        end

        def as_text
          s = ''
          expected_realm_types.sort.each do |key, rules|
            s << "#{key} {\n"
            rules = rules.is_a?(Array) ? rules : [rules]
            rules.each do |rule|
              login_module = (rule.is_a?(Hash) ? rule['login_module'] : rule.to_s) || (raise "No login_module specified for #{k}")
              flag = (rule.is_a?(Hash) ? rule['flag'] : nil) || 'required'
              options = (rule.is_a?(Hash) ? rule['options'] : nil) || {}
              s << "    #{login_module} #{flag} #{options.collect { |k, v| "#{k}=#{v}" }.join(' ') };\n"
            end
            s << "};\n"
          end
          s
        end

        def expected_realm_types
          (self.default_realm_types ? self.domain_version.default_realm_types : {}).merge(self.realm_types)
        end

        def instance_key
          "default_realm_types=#{self.default_realm_types}, realm_types='#{self.realm_types.keys.join(',')}'"
        end
      end
    end
  end
end
