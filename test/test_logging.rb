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

require File.expand_path('../helper', __FILE__)

class Redfish::TestLogging < Redfish::TestCase
  module MyModule
  end

  def test_basic_operation
    io = StringIO.new('', 'w')
    Redfish::Logging.configure(MyModule, ::Logger::INFO, io)

    assert_equal true, MyModule::Logger.is_a?(::Logger)

    MyModule.debug('Debug output')

    assert_equal io.string, ''

    MyModule.info('Info output')

    assert_equal io.string, "Info output\n"

    MyModule.warn('Warn output')

    assert_equal io.string, "Info output\nWarn output\n"

    assert_raises(RuntimeError) { MyModule.error('Error output') }

    assert_equal io.string, "Info output\nWarn output\nError output\n"

    MyModule::Logger.level = ::Logger::DEBUG

    MyModule.debug('Debug output')

    assert_equal io.string, "Info output\nWarn output\nError output\nDebug output\n"
  end

  def test_set_levels
    logger1 = ::Logger.new(STDOUT)
    logger1.level = ::Logger::INFO
    logger2 = ::Logger.new(STDOUT)
    logger2.level = ::Logger::WARN

    loggers = [logger1, logger2]

    assert_equal ::Logger::INFO, logger1.level
    assert_equal ::Logger::WARN, logger2.level

    Redfish::Logging.set_levels(::Logger::DEBUG, *loggers) do
      assert_equal ::Logger::DEBUG, logger1.level
      assert_equal ::Logger::DEBUG, logger2.level
    end

    assert_equal ::Logger::INFO, logger1.level
    assert_equal ::Logger::WARN, logger2.level

    Redfish::Logging.set_levels([::Logger::DEBUG, ::Logger::INFO], *loggers) do
      assert_equal ::Logger::DEBUG, logger1.level
      assert_equal ::Logger::INFO, logger2.level
    end

    assert_equal ::Logger::INFO, logger1.level
    assert_equal ::Logger::WARN, logger2.level

    Redfish::Logging.set_levels([::Logger::DEBUG, ::Logger::INFO], *loggers)
    assert_equal ::Logger::DEBUG, logger1.level
    assert_equal ::Logger::INFO, logger2.level
  end

  class MyModule2
  end

  class MyFakeTest
    include Test::Unit::Assertions
    include Redfish::Logging::Assertions
  end

  def test_assertions
    mytest = MyFakeTest.new

    io = StringIO.new('', 'w')
    Redfish::Logging.configure(MyModule2, ::Logger::INFO, io)

    assert_raises(RuntimeError.new('capture_logging called but no block supplied.')) do
      mytest.capture_logging(MyModule2)
    end
    assert_raises(RuntimeError.new('assert_logging_message called but no block supplied.')) do
      mytest.assert_logging_message(MyModule2, 'X')
    end
    assert_raises(RuntimeError.new('assert_logging_error called but no block supplied.')) do
      mytest.assert_logging_error(MyModule2, 'X')
    end

    messages = mytest.capture_logging(MyModule2) do
      MyModule2.info('Hello from log system')
    end
    assert_equal "Hello from log system\n", messages

    assert_raises(RuntimeError.new('assert_logging_message called but no block supplied.')) do
      mytest.assert_logging_message(MyModule2, 'Hello from log system')
    end

    mytest.assert_logging_message(MyModule2, 'Hello from log system') do
      MyModule2.info('Hello from log system')
    end

    assert_raises(Test::Unit::AssertionFailedError) do
      mytest.assert_logging_message(MyModule2, 'Hello from log system') do
      end
    end

    assert_raises(Test::Unit::AssertionFailedError) do
      mytest.assert_logging_error(MyModule2, 'Hello from log system') do
        MyModule2.info('Hello from log system')
      end
    end

    mytest.assert_logging_error(MyModule2, 'Error!') do
      MyModule2.error('Error!')
    end
  end
end
