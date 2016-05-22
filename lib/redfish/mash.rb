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
  class Mash < Hash
    alias_method :h_read, :[]
    alias_method :h_write, :[]=

    def [](key)
      self.h_write(key, Mash.new) unless key?(key)
      self.h_read(key)
    end

    def to_h
      result = {}
      each_pair do |key, value|
        result[key] = value.is_a?(Mash) ? value.to_h : value.is_a?(Fixnum) ? value : value.dup
      end
      result
    end
  end
end
