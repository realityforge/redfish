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

class Redfish::TestMash < Redfish::TestCase
  def test_mash
    m = Redfish::Mash.new
    assert_equal m.keys.size, 0
    assert m['hello'].is_a?(Redfish::Mash)
    assert_equal m.keys.size, 1
    m['hello']['bar'] = 1
    assert_equal m.keys.size, 1
    assert_equal m['hello'].keys.size, 1
    assert_equal m['hello']['bar'], 1
  end
end
