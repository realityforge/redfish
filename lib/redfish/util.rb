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
  module Util
    class << self
      # Generate a random password with lowercase, uppercase and numeric values
      def generate_password(size = 10)
        set = (('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a)
        set[rand(set.length)]
        size.times.map { set[rand(set.length)] }.join
      end

      def is_buildr_present?
        return true if defined?(::Buildr)
        begin
          require 'buildr'
        rescue Exception
          # ignored
        end
        defined?(::Buildr)
      end
    end
  end
end
