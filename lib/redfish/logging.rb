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

require 'logger'
require 'stringio'

module Redfish
  module Logging
    class << self
      def set_levels(levels, *loggers)
        if levels.is_a?(Array) && levels.size != loggers.size
          raise "Attempting to set log levels using an array of size #{levels.size} that does not match the number of loggers supplied #{loggers.size}"
        end

        if block_given?
          saved_levels = []
          loggers.each_with_index do |logger, index|
            saved_levels[index] = logger.level
          end
          begin
            loggers.each_with_index do |logger, index|
              logger.level = levels.is_a?(Array) ? levels[index] : levels
            end
            yield
          ensure
            loggers.each_with_index do |logger, index|
              logger.level = saved_levels[index]
            end
          end
        else
          loggers.each_with_index do |logger, index|
            logger.level = levels.is_a?(Array) ? levels[index] : levels
          end
        end
      end

      def configure(module_type, level = ::Logger::INFO, stream = STDOUT)
        logger = ::Logger.new(stream)
        logger.level = level
        logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }

        module_type.const_set(:Logger, logger)
        module_type.instance_eval do
          def self.debug(message)
            self.const_get(:Logger).debug(message)
          end

          def self.info(message)
            self.const_get(:Logger).info(message)
          end

          def self.warn(message)
            self.const_get(:Logger).warn(message)
          end

          def self.error(message)
            self.const_get(:Logger).error(message)
            raise message
          end
        end
      end
    end

    module Assertions
      def capture_logging(log_container, &block)
        raise 'capture_logging called but no block supplied.' unless block_given?
        logger = log_container.const_get(:Logger)

        logdev = logger.instance_variable_get('@logdev')
        original_dev = logdev.instance_variable_get('@dev')

        capture_io = StringIO.new
        begin
          logdev.instance_variable_set('@dev', capture_io)
          yield block
          return capture_io.string
        ensure
          logdev.instance_variable_set('@dev', original_dev)
        end
      end

      def assert_logging_message(log_container, expected_message, &block)
        raise 'assert_logging_message called but no block supplied.' unless block_given?

        result = capture_logging(log_container) do
          yield block
        end

        assert_equal "#{expected_message}\n", result
      end

      def assert_logging_error(log_container, expected_message, &block)
        raise 'assert_logging_error called but no block supplied.' unless block_given?
        assert_logging_message(log_container, expected_message) do
          assert_raise(RuntimeError.new(expected_message)) do
            yield block
          end
        end
      end
    end
  end
end
