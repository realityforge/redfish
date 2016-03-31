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
  Logger = ::Logger.new(STDOUT)
  Logger.level = ::Logger::INFO
  Logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n"}

  def self.debug(message)
    Logger.debug(message)
  end

  def self.info(message)
    Logger.info(message)
  end

  def self.warn(message)
    Logger.warn(message)
  end

  def self.error(message)
    Logger.error(message)
    raise message
  end

  class BaseElement
    def initialize(options = {})
      self.options = options
      yield self if block_given?
    end

    def options=(options)
      options.each_pair do |k, v|
        keys = k.to_s.split('.')
        target = self
        keys[0, keys.length - 1].each do |target_accessor_key|
          target = target.send target_accessor_key.to_sym
        end
        target.send "#{keys.last}=", v
      end
    end
  end
end
