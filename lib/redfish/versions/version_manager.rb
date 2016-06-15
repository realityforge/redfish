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
  class VersionManager
    class << self
      def register_version(version)
        raise "Unable to register version. There already exists a version with the key #{version.version_key.to_s}" if self.version_map[version.version_key.to_s]
        self.version_map[version.version_key.to_s] = version
      end

      def version_by_version_key(version_key)
        version = self.version_map[version_key.to_s]
        raise "No glassfish version registered with the version id '#{version_key}'" unless version
        version
      end

      def version_by_version_key?(version_key)
        !!self.version_map[version_key.to_s]
      end

      def versions
        self.version_map.values
      end

      protected

      def version_map
        @versions ||= {}
      end
    end
  end

  module Versions
    class BaseVersion

      def initialize(version_key, variant, version)
        raise "Variant '#{variant.inspect}' not valid. Valid variants include #{self.class.valid_variants.inspect}." unless self.class.valid_variants.include?(variant)
        @version_key = version_key
        @variant = variant
        @version = version
      end

      attr_reader :version_key
      attr_reader :variant
      attr_reader :version

      def payara?
        self.variant == :payara
      end

      def glassfish?
        self.variant == :glassfish
      end

      def self.valid_variants
        [:payara, :glassfish]
      end

      def support_log_jdbc_calls?
        false
      end

      def default_log_levels
        raise 'default_log_levels not implemented'
      end

      def default_log_attributes
        raise 'default_log_attributes not implemented'
      end

      def default_jvm_defines
        raise 'default_jvm_defines not implemented'
      end

      def default_realm_types
        raise 'default_realm_types not implemented'
      end
    end
  end
end
