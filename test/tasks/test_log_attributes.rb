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
    data = {'log_attributes' => {'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

    setup_interpreter_expects(executor, context, '')

    executor.expects(:exec).with(equals(context),
                                 equals('list-log-attributes'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(context),
                                 equals('set-log-attributes'),
                                 equals(%w(handlers=java.util.logging.ConsoleHandler:java.util.logging.ConsoleHandler.formatter=com.sun.enterprise.server.logging.UniformLogFormatter)),
                                 equals({})).
      returns('')

    perform_interpret(context, data, true, :set)
  end

  def test_interpret_set_when_matches
    data = {'log_attributes' => {'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}}

    executor = Redfish::Executor.new
    context = create_simple_context(executor)

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

    assert_equal t.to_s, 'log_attributes[handlers=java.util.logging.ConsoleHandler,java.util.logging.ConsoleHandler.formatter=com.sun.enterprise.server.logging.UniformLogFormatter]'
  end

  def test_set_when_attributes_no_match
    executor = Redfish::Executor.new
    t = new_task(executor)

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

    t.attributes = {'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_attributes_partially_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-attributes'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("handlers\t<X>\njava.util.logging.ConsoleHandler.formatter\t<com.sun.enterprise.server.logging.UniformLogFormatter>\njava.util.logging.FileHandler.count\t<1>")
    executor.expects(:exec).with(equals(t.context),
                                 equals('set-log-attributes'),
                                 equals(%w(handlers=java.util.logging.ConsoleHandler:java.util.logging.ConsoleHandler.formatter=com.sun.enterprise.server.logging.UniformLogFormatter)),
                                 equals({})).
      returns('')

    t.attributes = {'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end

  def test_set_when_attributes_match
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-log-attributes'),
                                 equals([]),
                                 equals(:terse => true, :echo => false)).
      returns("handlers\t<java.util.logging.ConsoleHandler>\njava.util.logging.ConsoleHandler.formatter\t<com.sun.enterprise.server.logging.UniformLogFormatter>\njava.util.logging.FileHandler.count\t<1>")

    t.attributes = {'handlers' => 'java.util.logging.ConsoleHandler', 'java.util.logging.ConsoleHandler.formatter' => 'com.sun.enterprise.server.logging.UniformLogFormatter'}
    t.perform_action(:set)

    ensure_task_not_updated_by_last_action(t)
  end
end
