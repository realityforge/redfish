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

class Redfish::Tasks::TestLogAttributes < Redfish::Tasks::BaseTaskTest
  def test_interpret_set
    data = {'logging' => {'attributes' => {'managed' => true, 'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    context.cache_properties('domain.version' => '270')

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('list-log-attributes'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('set-log-attributes'),
                                 equals(%w(--validate=false handlers=java.util.logging.ConsoleHandler:handlerServices=com.sun.enterprise.server.logging.GFFileHandler,com.sun.enterprise.server.logging.SyslogHandler:java.util.logging.ConsoleHandler.formatter=com.sun.enterprise.server.logging.UniformLogFormatter:com.sun.enterprise.server.logging.GFFileHandler.formatter=com.sun.enterprise.server.logging.ODLLogFormatter:com.sun.enterprise.server.logging.GFFileHandler.file=${com.sun.aas.instanceRoot}/logs/server.log:com.sun.enterprise.server.logging.GFFileHandler.rotationTimelimitInMinutes=0:com.sun.enterprise.server.logging.GFFileHandler.flushFrequency=1:java.util.logging.FileHandler.limit=50000:com.sun.enterprise.server.logging.GFFileHandler.logtoConsole=false:com.sun.enterprise.server.logging.GFFileHandler.rotationLimitInBytes=2000000:com.sun.enterprise.server.logging.GFFileHandler.excludeFields=:com.sun.enterprise.server.logging.GFFileHandler.multiLineMode=true:com.sun.enterprise.server.logging.SyslogHandler.useSystemLogging=false:java.util.logging.FileHandler.count=1:com.sun.enterprise.server.logging.GFFileHandler.retainErrorsStasticsForHours=0:log4j.logger.org.hibernate.validator.util.Version=warn:com.sun.enterprise.server.logging.GFFileHandler.maxHistoryFiles=0:com.sun.enterprise.server.logging.GFFileHandler.rotationOnDateChange=false:java.util.logging.FileHandler.pattern=%h/java%u.log:java.util.logging.FileHandler.formatter=java.util.logging.XMLFormatter)),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :set)
  end

  def test_interpret_set_when_matches
    data = {'logging' => {'default_attributes' => false, 'attributes' => {'managed' => true, 'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    context.cache_properties('domain.version' => '270')

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('list-log-attributes'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("handlers\t<java.util.logging.ConsoleHandler>\njava.util.logging.ConsoleHandler.formatter\t<com.sun.enterprise.server.logging.UniformLogFormatter>\njava.util.logging.FileHandler.count\t<1>")

    perform_interpret(context, data, false, :set)
  end

  def test_to_s
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.attributes = {'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}

    assert_equal t.to_s, "log_attributes[default_attributes=true, attributes='handlers=java.util.logging.ConsoleHandler,java.util.logging.ConsoleHandler.formatter=com.sun.enterprise.server.logging.UniformLogFormatter']"
  end

  def test_set_when_attributes_no_match_with_no_defaults
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('domain.version' => '270')

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-attributes'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('set-log-attributes'),
                                 equals(%w(handlers=java.util.logging.ConsoleHandler:java.util.logging.ConsoleHandler.formatter=com.sun.enterprise.server.logging.UniformLogFormatter)),
                                 equals({})).
      returns('')

    t.default_attributes = false
    t.attributes = {'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_attributes_no_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('domain.version' => '270')

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-attributes'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('set-log-attributes'),
                                 equals(%w(--validate=false handlers=java.util.logging.ConsoleHandler:handlerServices=com.sun.enterprise.server.logging.GFFileHandler,com.sun.enterprise.server.logging.SyslogHandler:java.util.logging.ConsoleHandler.formatter=com.sun.enterprise.server.logging.UniformLogFormatter:com.sun.enterprise.server.logging.GFFileHandler.formatter=com.sun.enterprise.server.logging.ODLLogFormatter:com.sun.enterprise.server.logging.GFFileHandler.file=${com.sun.aas.instanceRoot}/logs/server.log:com.sun.enterprise.server.logging.GFFileHandler.rotationTimelimitInMinutes=0:com.sun.enterprise.server.logging.GFFileHandler.flushFrequency=1:java.util.logging.FileHandler.limit=50000:com.sun.enterprise.server.logging.GFFileHandler.logtoConsole=false:com.sun.enterprise.server.logging.GFFileHandler.rotationLimitInBytes=2000000:com.sun.enterprise.server.logging.GFFileHandler.excludeFields=:com.sun.enterprise.server.logging.GFFileHandler.multiLineMode=true:com.sun.enterprise.server.logging.SyslogHandler.useSystemLogging=false:java.util.logging.FileHandler.count=1:com.sun.enterprise.server.logging.GFFileHandler.retainErrorsStasticsForHours=0:log4j.logger.org.hibernate.validator.util.Version=warn:com.sun.enterprise.server.logging.GFFileHandler.maxHistoryFiles=0:com.sun.enterprise.server.logging.GFFileHandler.rotationOnDateChange=false:java.util.logging.FileHandler.pattern=%h/java%u.log:java.util.logging.FileHandler.formatter=java.util.logging.XMLFormatter)),
                                 equals({})).
      returns('')

    t.attributes = {'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_attributes_partially_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('domain.version' => '270')

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-attributes'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("handlers\t<X>\njava.util.logging.ConsoleHandler.formatter\t<com.sun.enterprise.server.logging.UniformLogFormatter>\njava.util.logging.FileHandler.count\t<1>")
    executor.expects(:exec).with(equals(t.context),
                                 equals('set-log-attributes'),
                                 equals(%w(--validate=false handlers=java.util.logging.ConsoleHandler:handlerServices=com.sun.enterprise.server.logging.GFFileHandler,com.sun.enterprise.server.logging.SyslogHandler:java.util.logging.ConsoleHandler.formatter=com.sun.enterprise.server.logging.UniformLogFormatter:com.sun.enterprise.server.logging.GFFileHandler.formatter=com.sun.enterprise.server.logging.ODLLogFormatter:com.sun.enterprise.server.logging.GFFileHandler.file=${com.sun.aas.instanceRoot}/logs/server.log:com.sun.enterprise.server.logging.GFFileHandler.rotationTimelimitInMinutes=0:com.sun.enterprise.server.logging.GFFileHandler.flushFrequency=1:java.util.logging.FileHandler.limit=50000:com.sun.enterprise.server.logging.GFFileHandler.logtoConsole=false:com.sun.enterprise.server.logging.GFFileHandler.rotationLimitInBytes=2000000:com.sun.enterprise.server.logging.GFFileHandler.excludeFields=:com.sun.enterprise.server.logging.GFFileHandler.multiLineMode=true:com.sun.enterprise.server.logging.SyslogHandler.useSystemLogging=false:java.util.logging.FileHandler.count=1:com.sun.enterprise.server.logging.GFFileHandler.retainErrorsStasticsForHours=0:log4j.logger.org.hibernate.validator.util.Version=warn:com.sun.enterprise.server.logging.GFFileHandler.maxHistoryFiles=0:com.sun.enterprise.server.logging.GFFileHandler.rotationOnDateChange=false:java.util.logging.FileHandler.pattern=%h/java%u.log:java.util.logging.FileHandler.formatter=java.util.logging.XMLFormatter)),
                                 equals({})).
      returns('')

    t.attributes = {'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_attributes_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('domain.version' => '270')

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-attributes'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("handlers\t<java.util.logging.ConsoleHandler>\njava.util.logging.ConsoleHandler.formatter\t<com.sun.enterprise.server.logging.UniformLogFormatter>\njava.util.logging.FileHandler.count\t<1>")

    t.default_attributes = false
    t.attributes = {'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}
    t.perform_action(:set)

    ensure_task_not_updated_by_last_action(t)
  end
end
