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
  class Config
    class << self
      attr_writer :base_directory

      # Base directory where artifacts are generated
      def base_directory
        return @base_directory unless @base_directory.nil?
        if defined?(::Buildr)
          File.dirname(::Buildr.application.buildfile.to_s) rescue '.'
        else
          '.'
        end
      end

      attr_writer :task_prefix

      def task_prefix
        @task_prefix || 'redfish'
      end

      attr_writer :default_glassfish_home

      def default_glassfish_home
        @default_glassfish_home ||
          ENV['GLASSFISH_HOME'] ||
          (Redfish.error("Unable to determine default_glassfish_home, GLASSFISH_HOME environment variable not specified. Please specify using Redfish::Config.default_glassfish_home = '/path/to/glassfish'"))
      end

      attr_writer :default_domains_directory

      def default_domains_directory
        @default_domains_directory ||
          ENV['GLASSFISH_DOMAINS_DIR'] ||
          "#{self.default_glassfish_home}/glassfish/domains"
      end

      attr_writer :default_domain_key

      def default_domain_key
        @default_domain_key || Redfish.error("Unable to determine default_domain_key. Please specify using Redfish::Config.default_domain_key = 'myapp'")
      end

      def default_domain_key?(domain_key)
        return false if @default_domain_key.nil?
        self.default_domain_key.to_s == domain_key.to_s
      end
    end
  end
end
