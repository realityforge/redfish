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
  class << self
    def brokers
      broker_map.values
    end

    def broker_by_key?(key)
      !!broker_map[key.to_s]
    end

    def broker_by_key(key)
      broker_map[key.to_s] || (raise "Broker with key #{key} not defined")
    end

    def broker(key, options = {})
      raise "Broker with key #{key} already defined" if broker_by_key?(key)
      broker = BrokerDefinition.new(key, options)
      broker_map[key.to_s] = broker
      yield broker if block_given?
      broker
    end

    protected

    def broker_map
      @brokers ||= {}
    end
  end
end
