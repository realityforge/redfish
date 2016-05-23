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
    def domains
      domain_map.values
    end

    def domain_by_name?(name)
      !!domain_map[name.to_s]
    end

    def domain_by_name(name)
      domain_map[name.to_s] || (raise "Domain named #{name} not defined")
    end

    def domain(name)
      raise "Domain named #{name} already defined" if domain_by_name?(name)
      domain = DomainDefinition.new(name)
      domain_map[name.to_s] = domain
      yield domain if block_given?
      domain
    end

    protected

    def domain_map
      @domains ||= {}
    end
  end
end
