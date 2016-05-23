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

  def test_from
    m = Redfish::Mash.from('a' => {'b' => 1}, 'c' => true)
    assert_equal m.keys.size, 2
    assert m['a'].is_a?(Redfish::Mash)
    assert_equal m['a'].keys.size, 1
    assert_equal m['a']['b'], 1
    assert_equal m['c'], true
  end

  def test_to_h
    m = Redfish::Mash.new
    m['a'] = 1
    m['b'] = 's'
    m['c'] = true
    m['d'] = false
    m['e'] = 4.3
    m['f']['a'] = 1
    m['f']['b'] = 's'
    m['f']['c'] = true
    m['f']['d'] = false
    m['f']['e'] = 4.3
    m['f']['f']['a'] = 1
    m['f']['f']['b'] = 's'
    m['f']['f']['c'] = true
    m['f']['f']['d'] = false
    m['f']['f']['e'] = 4.3
    h = m.to_h
    assert_equal h['g'], nil
    assert_equal h['a'], 1
    assert_equal h['b'], 's'
    assert_equal h['c'], true
    assert_equal h['d'], false
    assert_equal h['e'], 4.3
    assert_equal h['f']['a'], 1
    assert_equal h['f']['b'], 's'
    assert_equal h['f']['c'], true
    assert_equal h['f']['d'], false
    assert_equal h['f']['e'], 4.3
    assert_equal h['f']['f']['a'], 1
    assert_equal h['f']['f']['b'], 's'
    assert_equal h['f']['f']['c'], true
    assert_equal h['f']['f']['d'], false
    assert_equal h['f']['f']['e'], 4.3
  end
end
