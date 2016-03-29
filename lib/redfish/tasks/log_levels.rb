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
    class LogLevels < AsadminTask
      private

      attribute :levels, :kind_of => Hash, :required => true, :custom_validation => true
      attribute :default_levels, :type => :boolean, :default => true

      def validate_levels(levels)
        levels.each_pair do |key, value|
          unless %w(SEVERE WARNING INFO CONFIG FINE FINER FINSEST ALL).include?(value)
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

          updated_by_last_action
        end
      end

      def instance_key
        self.levels.collect{|k,v| "#{k}=#{v}"}.join(',')
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
        (self.default_levels ? default_log_levels : {}).merge(self.levels)
      end

      def default_log_levels
        c = self.domain_version
        if c[:variant] == 'Payara' && c[:version] == '4.1.1.154'
          {
            'com.sun.enterprise.server.logging.GFFileHandler.level' => 'ALL',
            'com.sun.enterprise.server.logging.SyslogHandler.level' => 'ALL',
            'javax.enterprise.system.tools.admin.level' => 'INFO',
            'org.apache.jasper.level' => 'INFO',
            'javax.enterprise.system.core.level' => 'INFO',
            'javax.enterprise.system.core.classloading.level' => 'INFO',
            'java.util.logging.ConsoleHandler.level' => 'FINEST',
            'javax.enterprise.system.tools.deployment.level' => 'INFO',
            'javax.enterprise.system.core.transaction.level' => 'INFO',
            'org.apache.catalina.level' => 'INFO',
            'org.apache.coyote.level' => 'INFO',
            'javax.level' => 'INFO',
            'javax.enterprise.system.util.level' => 'INFO',
            'javax.enterprise.resource.resourceadapter.level' => 'INFO',
            'javax.enterprise.system.core.config.level' => 'INFO',
            'javax.enterprise.system.level' => 'INFO',
            'javax.enterprise.system.core.security.level' => 'INFO',
            'javax.enterprise.system.container.cmp.level' => 'INFO',
            'javax.enterprise.system.core.selfmanagement.level' => 'INFO',
            '.level' => 'INFO',
            'javax.enterprise.resource.jdo.level' => 'INFO',
            'javax.enterprise.resource.sqltrace.level' => 'FINE',
            'org.jvnet.hk2.osgiadapter.level' => 'INFO',
            'javax.enterprise.system.ssl.security.level' => 'INFO',
            'ShoalLogger.level' => 'CONFIG',
            'javax.enterprise.resource.corba.level' => 'INFO',
            'javax.enterprise.resource.jta.level' => 'INFO',
            'javax.enterprise.system.webservices.saaj.level' => 'INFO',
            'javax.enterprise.system.container.ejb.level' => 'INFO',
            'javax.enterprise.system.container.ejb.mdb.level' => 'INFO',
            'javax.enterprise.resource.javamail.level' => 'INFO',
            'javax.enterprise.system.webservices.rpc.level' => 'INFO',
            'javax.enterprise.system.container.web.level' => 'INFO',
            'javax.enterprise.resource.jms.level' => 'INFO',
            'javax.enterprise.system.webservices.registry.level' => 'INFO',
            'javax.enterprise.resource.webcontainer.jsf.application.level' => 'INFO',
            'javax.enterprise.resource.webcontainer.jsf.resource.level' => 'INFO',
            'javax.enterprise.resource.webcontainer.jsf.config.level' => 'INFO',
            'javax.enterprise.resource.webcontainer.jsf.context.level' => 'INFO',
            'javax.enterprise.resource.webcontainer.jsf.facelets.level' => 'INFO',
            'javax.enterprise.resource.webcontainer.jsf.lifecycle.level' => 'INFO',
            'javax.enterprise.resource.webcontainer.jsf.managedbean.level' => 'INFO',
            'javax.enterprise.resource.webcontainer.jsf.renderkit.level' => 'INFO',
            'javax.enterprise.resource.webcontainer.jsf.taglib.level' => 'INFO',
            'javax.enterprise.resource.webcontainer.jsf.timing.level' => 'INFO',
            'javax.org.glassfish.persistence.level' => 'INFO',
            'javax.enterprise.system.tools.backup.level' => 'INFO',
            'org.glassfish.admingui.level' => 'INFO',
            'org.glassfish.naming.level' => 'INFO',
            'org.eclipse.persistence.session.level' => 'INFO',
            'javax.enterprise.system.tools.deployment.dol.level' => 'WARNING',
            'javax.enterprise.system.tools.deployment.common.level' => 'WARNING',
          }
        else
          raise "Unable to derive default log levels for version #{c.inspect}"
        end
      end
    end
  end
end
