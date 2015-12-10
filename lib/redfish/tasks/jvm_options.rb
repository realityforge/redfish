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
    class JvmOptions < AsadminTask
      private

      attribute :jvm_options, :kind_of => Array, :default => []
      attribute :defines, :kind_of => Hash, :default => {}
      attribute :default_defines, :type => :boolean, :default => true

      action :set do
        existing = current_options
        expected = expected_options

        if existing != expected
          context.exec('delete-jvm-options', [encode_options(existing)])
          context.exec('create-jvm-options', [encode_options(expected)])

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
          defines.merge!(derive_default_defines)
        end
        defines.merge!(self.defines)
        defines
      end

      def derive_default_defines
        c = context.property_cache? ?
          context.domain_version :
          context.domain_version(get_property('domain.version'))

        if c[:variant] == 'Payara' && c[:version] == '4.1.152'
           {
            'java.awt.headless' => 'true',
            'jdk.corba.allowOutputStreamSubclass' => 'true',
            'java.endorsed.dirs' => '${com.sun.aas.installRoot}/modules/endorsed${path.separator}${com.sun.aas.installRoot}/lib/endorsed',
            'java.security.policy' => '${com.sun.aas.instanceRoot}/config/server.policy',
            'java.security.auth.login.config' => '${com.sun.aas.instanceRoot}/config/login.conf',
            'com.sun.enterprise.security.httpsOutboundKeyAlias' => 's1as',
            'javax.net.ssl.keyStore' => '${com.sun.aas.instanceRoot}/config/keystore.jks',
            'javax.net.ssl.trustStore' => '${com.sun.aas.instanceRoot}/config/cacerts.jks',
            'java.ext.dirs' => '${com.sun.aas.javaRoot}/lib/ext${path.separator}${com.sun.aas.javaRoot}/jre/lib/ext${path.separator}${com.sun.aas.instanceRoot}/lib/ext',
            'jdbc.drivers' => 'org.apache.derby.jdbc.ClientDriver',
            'ANTLR_USE_DIRECT_CLASS_LOADING' => 'true',
            'com.sun.enterprise.config.config_environment_factory_class' => 'com.sun.enterprise.config.serverbeans.AppserverConfigEnvironmentFactory',
            'jdk.tls.rejectClientInitiatedRenegotiation' => 'true',

            # The following removed in 154
            'javax.xml.accessExternalSchema' => 'all',
            'javax.management.builder.initial' => 'com.sun.enterprise.v3.admin.AppServerMBeanServerBuilder',
            'com.ctc.wstx.returnNullForDefaultNamespace' => 'true'
          }
        elsif c[:variant] == 'Payara' && c[:version] == '4.1.1.154'
          {
            'java.awt.headless' => 'true',
            'jdk.corba.allowOutputStreamSubclass' => 'true',
            'java.endorsed.dirs' => '${com.sun.aas.installRoot}/modules/endorsed${path.separator}${com.sun.aas.installRoot}/lib/endorsed',
            'java.security.policy' => '${com.sun.aas.instanceRoot}/config/server.policy',
            'java.security.auth.login.config' => '${com.sun.aas.instanceRoot}/config/login.conf',
            'com.sun.enterprise.security.httpsOutboundKeyAlias' => 's1as',
            'javax.net.ssl.keyStore' => '${com.sun.aas.instanceRoot}/config/keystore.jks',
            'javax.net.ssl.trustStore' => '${com.sun.aas.instanceRoot}/config/cacerts.jks',
            'java.ext.dirs' => '${com.sun.aas.javaRoot}/lib/ext${path.separator}${com.sun.aas.javaRoot}/jre/lib/ext${path.separator}${com.sun.aas.instanceRoot}/lib/ext',
            'jdbc.drivers' => 'org.apache.derby.jdbc.ClientDriver',
            'ANTLR_USE_DIRECT_CLASS_LOADING' => 'true',
            'com.sun.enterprise.config.config_environment_factory_class' => 'com.sun.enterprise.config.serverbeans.AppserverConfigEnvironmentFactory',
            'jdk.tls.rejectClientInitiatedRenegotiation' => 'true',
            'org.jboss.weld.serialization.beanIdentifierIndexOptimization' => 'false'
          }
        else
          raise "Unable to derive default defines for version #{c.inspect}"
        end
      end

      def current_options
        context.exec('list-jvm-options', [], :terse => true, :echo => false).split("\n")
      end
    end
  end
end
