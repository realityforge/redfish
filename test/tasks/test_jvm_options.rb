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

require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestJvmOptions < Redfish::Tasks::BaseTaskTest
  def test_interpret_set
    data = {'jvm_options' => {'options' => ['-XMagic'], 'defines' => {'A' => 'B:1'}, 'default_defines' => false}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    mock_property_get(executor, context, 'configs.config.server-config.java-config.jvm-options=-DMyDefine=true,-DMyOtherDefine=true,-A=B:1')

    executor.expects(:exec).with(equals(context),
                                 equals('delete-jvm-options'),
                                 equals(%w(-DMyDefine=true:-DMyOtherDefine=true:-A=B\:1)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('create-jvm-options'),
                                 equals(%w(-DA=B\\:1:-XMagic)),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :set, :exclude_jvm_options => true)
  end

  def test_interpret_set_when_matches
    data = {'jvm_options' => {'options' => ['-XMagic'], 'defines' => {'A' => 'B:1'}, 'default_defines' => false}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    mock_property_get(executor, context, "configs.config.server-config.java-config.jvm-options=-DA=B:1,-XMagic\n")

    perform_interpret(context, data, false, :set, :exclude_jvm_options => true)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.jvm_options = ['-XMagic']
    t.defines = {'A' => 'B:1'}
    t.default_defines = true

    assert_equal t.to_s, 'jvm_options[default_defines=true options=["-XMagic"] defines={"A"=>"B:1"}]'
  end

  def test_set_when_attributes_no_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('configs.config.server-config.java-config.jvm-options' => '-DMyDefine=true,-DMyOtherDefine=true,-A=B:1')

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jvm-options'),
                                 equals(%w(-DMyDefine=true:-DMyOtherDefine=true:-A=B\:1)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jvm-options'),
                                 equals(%w(-DA=B\\:1:-XMagic)),
                                 equals({})).
      returns('')


    t.jvm_options = ['-XMagic']
    t.defines = {'A' => 'B:1'}
    t.default_defines = false
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_attributes_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('configs.config.server-config.java-config.jvm-options' => '-DA=B:1,-XMagic')

    t.jvm_options = ['-XMagic']
    t.defines = {'A' => 'B:1'}
    t.default_defines = false
    t.perform_action(:set)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_set_when_attributes_no_match_and_default_defines_included
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('domain.version' => '270',
                               'configs.config.server-config.java-config.jvm-options' => '-DMyDefine=true,-DMyOtherDefine=true,-A=B:1')

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-jvm-options'),
                                 equals(%w(-DMyDefine=true:-DMyOtherDefine=true:-A=B\:1)),
                                 equals({})).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-jvm-options'),
                                 equals(['-DA=B\\:1:-DANTLR_USE_DIRECT_CLASS_LOADING=true:-Dcom.sun.enterprise.config.config_environment_factory_class=com.sun.enterprise.config.serverbeans.AppserverConfigEnvironmentFactory:-Dcom.sun.enterprise.security.httpsOutboundKeyAlias=s1as:-Djava.awt.headless=true:-Djava.endorsed.dirs=${com.sun.aas.installRoot}/modules/endorsed${path.separator}${com.sun.aas.installRoot}/lib/endorsed:-Djava.ext.dirs=${com.sun.aas.javaRoot}/lib/ext${path.separator}${com.sun.aas.javaRoot}/jre/lib/ext${path.separator}${com.sun.aas.instanceRoot}/lib/ext:-Djava.security.auth.login.config=${com.sun.aas.instanceRoot}/config/login.conf:-Djava.security.policy=${com.sun.aas.instanceRoot}/config/server.policy:-Djavax.net.ssl.keyStore=${com.sun.aas.instanceRoot}/config/keystore.jks:-Djavax.net.ssl.trustStore=${com.sun.aas.instanceRoot}/config/cacerts.jks:-Djdbc.drivers=org.apache.derby.jdbc.ClientDriver:-Djdk.corba.allowOutputStreamSubclass=true:-Djdk.tls.rejectClientInitiatedRenegotiation=true:-Dorg.jboss.weld.serialization.beanIdentifierIndexOptimization=false:-XMagic']),
                                 equals({})).
      returns('')

    t.jvm_options = ['-XMagic']
    t.defines = {'A' => 'B:1'}
    t.default_defines = true
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end
end
