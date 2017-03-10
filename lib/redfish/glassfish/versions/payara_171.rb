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
  module Versions
    class Payara171 < BaseVersion

      def initialize
        super('137', :payara, '4.1.1.171_0_1')
      end

      def support_log_jdbc_calls?
        true
      end

      def default_log_levels
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
      end

      def default_log_attributes
        {
          'handlers' => 'java.util.logging.ConsoleHandler',
          'handlerServices' => 'com.sun.enterprise.server.logging.GFFileHandler,com.sun.enterprise.server.logging.SyslogHandler',
          'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter',
          'com.sun.enterprise.server.logging.GFFileHandler.formatter' => 'com.sun.enterprise.server.logging.ODLLogFormatter',
          'com.sun.enterprise.server.logging.GFFileHandler.file' => '${com.sun.aas.instanceRoot}/logs/server.log',
          'com.sun.enterprise.server.logging.GFFileHandler.rotationTimelimitInMinutes' => '0',
          'com.sun.enterprise.server.logging.GFFileHandler.flushFrequency' => '1',
          'com.sun.enterprise.server.logging.GFFileHandler.compressOnRotation' => 'false',
          'java.util.logging.FileHandler.limit' => '50000',
          'com.sun.enterprise.server.logging.GFFileHandler.logtoConsole' => 'false',
          'com.sun.enterprise.server.logging.GFFileHandler.rotationLimitInBytes' => '2000000',
          'com.sun.enterprise.server.logging.GFFileHandler.excludeFields' => '',
          'com.sun.enterprise.server.logging.GFFileHandler.multiLineMode' => 'true',
          'com.sun.enterprise.server.logging.SyslogHandler.useSystemLogging' => 'false',
          'java.util.logging.FileHandler.count' => '1',
          'com.sun.enterprise.server.logging.GFFileHandler.retainErrorsStasticsForHours' => '0',
          'log4j.logger.org.hibernate.validator.util.Version' => 'warn',
          'com.sun.enterprise.server.logging.GFFileHandler.maxHistoryFiles' => '0',
          'com.sun.enterprise.server.logging.GFFileHandler.rotationOnDateChange' => 'false',
          'java.util.logging.FileHandler.pattern' => '%h/java%u.log',
          'java.util.logging.FileHandler.formatter' => 'java.util.logging.XMLFormatter'
        }
      end

      def default_jvm_defines
        {
          'java.awt.headless' => 'true',
          'jdk.corba.allowOutputStreamSubclass' => 'true',
          'java.endorsed.dirs' => '${com.sun.aas.installRoot}/modules/endorsed${path.separator}${com.sun.aas.installRoot}/lib/endorsed',
          'java.security.policy' => '${com.sun.aas.instanceRoot}/config/server.policy',
          'java.security.auth.login.config' => '${com.sun.aas.instanceRoot}/config/login.conf',
          'javax.net.ssl.keyStore' => '${com.sun.aas.instanceRoot}/config/keystore.jks',
          'javax.net.ssl.trustStore' => '${com.sun.aas.instanceRoot}/config/cacerts.jks',
          'java.ext.dirs' => '${com.sun.aas.javaRoot}/lib/ext${path.separator}${com.sun.aas.javaRoot}/jre/lib/ext${path.separator}${com.sun.aas.instanceRoot}/lib/ext',
          'jdbc.drivers' => 'org.apache.derby.jdbc.ClientDriver',
          'ANTLR_USE_DIRECT_CLASS_LOADING' => 'true',
          'com.sun.enterprise.config.config_environment_factory_class' => 'com.sun.enterprise.config.serverbeans.AppserverConfigEnvironmentFactory',
          'jdk.tls.rejectClientInitiatedRenegotiation' => 'true',
          'org.jboss.weld.serialization.beanIdentifierIndexOptimization' => 'false',
          'com.sun.enterprise.security.httpsOutboundKeyAlias' => 's1as',
          'org.glassfish.grizzly.DEFAULT_MEMORY_MANAGER' => 'org.glassfish.grizzly.memory.HeapMemoryManager'
        }
      end

      def default_realm_types
        {
          'fileRealm' => 'com.sun.enterprise.security.auth.login.FileLoginModule',
          'ldapRealm' => 'com.sun.enterprise.security.auth.login.LDAPLoginModule',
          'solarisRealm' => 'com.sun.enterprise.security.auth.login.SolarisLoginModule',
          'jdbcRealm' => 'com.sun.enterprise.security.ee.auth.login.JDBCLoginModule',
          'jdbcDigestRealm' => 'com.sun.enterprise.security.ee.auth.login.JDBCDigestLoginModule',
          'pamRealm' => 'com.sun.enterprise.security.ee.auth.login.PamLoginModule'
        }
      end
    end
  end
end

Redfish::VersionManager.register_version(Redfish::Versions::Payara171.new)
