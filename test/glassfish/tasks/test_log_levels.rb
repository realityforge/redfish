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

require File.expand_path('../../../helper', __FILE__)

class Redfish::Tasks::Glassfish::TestLogLevels < Redfish::Tasks::Glassfish::BaseTaskTest
  def test_interpret_set
    data = {'logging' => {'default_levels' => true, 'levels' => {'managed' => true, 'iris' => 'WARNING', 'iris.planner' => 'INFO'}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('set-log-levels'),
                                 equals(%w(com.sun.enterprise.server.logging.GFFileHandler.level=ALL:com.sun.enterprise.server.logging.SyslogHandler.level=ALL:javax.enterprise.system.tools.admin.level=INFO:org.apache.jasper.level=INFO:javax.enterprise.system.core.level=INFO:javax.enterprise.system.core.classloading.level=INFO:java.util.logging.ConsoleHandler.level=FINEST:javax.enterprise.system.tools.deployment.level=INFO:javax.enterprise.system.core.transaction.level=INFO:org.apache.catalina.level=INFO:org.apache.coyote.level=INFO:javax.level=INFO:javax.enterprise.system.util.level=INFO:javax.enterprise.resource.resourceadapter.level=INFO:javax.enterprise.system.core.config.level=INFO:javax.enterprise.system.level=INFO:javax.enterprise.system.core.security.level=INFO:javax.enterprise.system.container.cmp.level=INFO:javax.enterprise.system.core.selfmanagement.level=INFO:.level=INFO:javax.enterprise.resource.jdo.level=INFO:javax.enterprise.resource.sqltrace.level=FINE:org.jvnet.hk2.osgiadapter.level=INFO:javax.enterprise.system.ssl.security.level=INFO:ShoalLogger.level=CONFIG:javax.enterprise.resource.corba.level=INFO:javax.enterprise.resource.jta.level=INFO:javax.enterprise.system.webservices.saaj.level=INFO:javax.enterprise.system.container.ejb.level=INFO:javax.enterprise.system.container.ejb.mdb.level=INFO:javax.enterprise.resource.javamail.level=INFO:javax.enterprise.system.webservices.rpc.level=INFO:javax.enterprise.system.container.web.level=INFO:javax.enterprise.resource.jms.level=INFO:javax.enterprise.system.webservices.registry.level=INFO:javax.enterprise.resource.webcontainer.jsf.application.level=INFO:javax.enterprise.resource.webcontainer.jsf.resource.level=INFO:javax.enterprise.resource.webcontainer.jsf.config.level=INFO:javax.enterprise.resource.webcontainer.jsf.context.level=INFO:javax.enterprise.resource.webcontainer.jsf.facelets.level=INFO:javax.enterprise.resource.webcontainer.jsf.lifecycle.level=INFO:javax.enterprise.resource.webcontainer.jsf.managedbean.level=INFO:javax.enterprise.resource.webcontainer.jsf.renderkit.level=INFO:javax.enterprise.resource.webcontainer.jsf.taglib.level=INFO:javax.enterprise.resource.webcontainer.jsf.timing.level=INFO:javax.org.glassfish.persistence.level=INFO:javax.enterprise.system.tools.backup.level=INFO:org.glassfish.admingui.level=INFO:org.glassfish.naming.level=INFO:org.eclipse.persistence.session.level=INFO:javax.enterprise.system.tools.deployment.dol.level=WARNING:javax.enterprise.system.tools.deployment.common.level=WARNING:iris=WARNING:iris.planner=INFO)),
                                 equals({})).
      returns('')

    setup_logging_file(context)

    perform_interpret(context, data, true, :set, :domain_dir_exists => true)

    check_default_logging_file(context)
  end

  def test_interpret_set_when_matches
    data = {'logging' => {'default_levels' => false, 'levels' => {'managed' => true, 'iris' => 'WARNING', 'iris.planner' => 'INFO'}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("other\t<INFO>\niris\t<WARNING>\niris.planner\t<INFO>\njavax\t<SEVERE>")

    perform_interpret(context, data, false, :set)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.levels = {'iris' => 'WARNING', 'iris.planner' => 'INFO'}

    assert_equal t.to_s, "log_levels[default_levels=true, levels='iris=WARNING,iris.planner=INFO']"
  end

  def test_set_when_levels_no_match_include_defaults
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('domain.version' => '270')

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('set-log-levels'),
                                 equals( %w(com.sun.enterprise.server.logging.GFFileHandler.level=ALL:com.sun.enterprise.server.logging.SyslogHandler.level=ALL:javax.enterprise.system.tools.admin.level=INFO:org.apache.jasper.level=INFO:javax.enterprise.system.core.level=INFO:javax.enterprise.system.core.classloading.level=INFO:java.util.logging.ConsoleHandler.level=FINEST:javax.enterprise.system.tools.deployment.level=INFO:javax.enterprise.system.core.transaction.level=INFO:org.apache.catalina.level=INFO:org.apache.coyote.level=INFO:javax.level=INFO:javax.enterprise.system.util.level=INFO:javax.enterprise.resource.resourceadapter.level=INFO:javax.enterprise.system.core.config.level=INFO:javax.enterprise.system.level=INFO:javax.enterprise.system.core.security.level=INFO:javax.enterprise.system.container.cmp.level=INFO:javax.enterprise.system.core.selfmanagement.level=INFO:.level=INFO:javax.enterprise.resource.jdo.level=INFO:javax.enterprise.resource.sqltrace.level=FINE:org.jvnet.hk2.osgiadapter.level=INFO:javax.enterprise.system.ssl.security.level=INFO:ShoalLogger.level=CONFIG:javax.enterprise.resource.corba.level=INFO:javax.enterprise.resource.jta.level=INFO:javax.enterprise.system.webservices.saaj.level=INFO:javax.enterprise.system.container.ejb.level=INFO:javax.enterprise.system.container.ejb.mdb.level=INFO:javax.enterprise.resource.javamail.level=INFO:javax.enterprise.system.webservices.rpc.level=INFO:javax.enterprise.system.container.web.level=INFO:javax.enterprise.resource.jms.level=INFO:javax.enterprise.system.webservices.registry.level=INFO:javax.enterprise.resource.webcontainer.jsf.application.level=INFO:javax.enterprise.resource.webcontainer.jsf.resource.level=INFO:javax.enterprise.resource.webcontainer.jsf.config.level=INFO:javax.enterprise.resource.webcontainer.jsf.context.level=INFO:javax.enterprise.resource.webcontainer.jsf.facelets.level=INFO:javax.enterprise.resource.webcontainer.jsf.lifecycle.level=INFO:javax.enterprise.resource.webcontainer.jsf.managedbean.level=INFO:javax.enterprise.resource.webcontainer.jsf.renderkit.level=INFO:javax.enterprise.resource.webcontainer.jsf.taglib.level=INFO:javax.enterprise.resource.webcontainer.jsf.timing.level=INFO:javax.org.glassfish.persistence.level=INFO:javax.enterprise.system.tools.backup.level=INFO:org.glassfish.admingui.level=INFO:org.glassfish.naming.level=INFO:org.eclipse.persistence.session.level=INFO:javax.enterprise.system.tools.deployment.dol.level=WARNING:javax.enterprise.system.tools.deployment.common.level=WARNING:iris=WARNING:iris.planner=INFO)),
                                 equals({})).
      returns('')

    setup_logging_file(t.context)

    t.levels = {'iris' => 'WARNING', 'iris.planner' => 'INFO'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)

    check_default_logging_file(t.context)
  end

  def test_set_when_levels_no_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('domain.version' => '270')

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('set-log-levels'),
                                 equals(%w(iris=WARNING:iris.planner=INFO)),
                                 equals({})).
      returns('')

    setup_logging_file(t.context)

    t.default_levels = false
    t.levels = {'iris' => 'WARNING', 'iris.planner' => 'INFO'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)

    check_default_logging_file(t.context)
  end

  def test_set_when_levels_partially_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('domain.version' => '270')

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("other\t<INFO>\niris\t<SEVERE>\niris.planner\t<INFO>\njavax\t<SEVERE>\niris.acal\t<INFO>")
    executor.expects(:exec).with(equals(t.context),
                                 equals('set-log-levels'),
                                 equals(%w(iris=WARNING:iris.acal=WARNING)),
                                 equals({})).
      returns('')

    setup_logging_file(t.context)

    t.default_levels = false
    t.levels = {'iris' => 'WARNING', 'iris.planner' => 'INFO', 'iris.acal' => 'WARNING'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)

    check_default_logging_file(t.context)
  end

  def test_set_when_levels_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('domain.version' => '270')

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-levels'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("other\t<INFO>\niris\t<WARNING>\niris.planner\t<INFO>\njavax\t<SEVERE>")

    t.default_levels = false
    t.levels = {'iris' => 'WARNING', 'iris.planner' => 'INFO'}
    t.perform_action(:set)

    ensure_task_not_updated_by_last_action(t)
  end

  def check_default_logging_file(context)
    default_logging_file = "#{context.domain_directory}/config/default-logging.properties"
    assert_equal IO.read(default_logging_file), 'Blah'
    assert_equal sprintf("%o", File::Stat.new(default_logging_file).mode)[-3, 3], '600'
  end

  def setup_logging_file(context)
    config_dir = "#{context.domain_directory}/config"
    FileUtils.mkdir_p config_dir
    File.open("#{config_dir}/logging.properties", 'wb') do |f|
      f.write 'Blah'
    end
  end
end
