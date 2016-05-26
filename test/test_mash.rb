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
    m['g'] = nil
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
    assert_equal h['g'], nil
  end

  def test_merge
    m = Redfish::Mash.new
    m['a'] = 1
    m['b'] = 's'
    m['c'] = true
    m['d'] = false
    m['e'] = 4.3
    m['f']['a'] = 1
    m['f']['b']['p'] = 1
    m['g'] = [1]

    m2 = Redfish::Mash.new
    m2['e'] = 4.2
    m2['f']['c'] = 1
    m2['f']['b']['q'] = 1
    m2['g'] = [3, 4]

    result = m.merge(m2)

    # Make sure m has not changed
    h = m.to_h
    assert_equal h['g'], [1]
    assert_equal h['a'], 1
    assert_equal h['b'], 's'
    assert_equal h['c'], true
    assert_equal h['d'], false
    assert_equal h['e'], 4.3
    assert_equal h['f']['a'], 1
    assert_equal h['f']['b']['p'], 1

    # Make sure m2 has not changed
    h = m2.to_h
    assert_equal h['e'], 4.2
    assert_equal h['f']['c'], 1
    assert_equal h['f']['b']['q'], 1
    assert_equal h['g'], [3, 4]

    h = result.to_h
    assert_equal h['g'], [1, 3, 4]
    assert_equal h['a'], 1
    assert_equal h['b'], 's'
    assert_equal h['c'], true
    assert_equal h['d'], false
    assert_equal h['e'], 4.2
    assert_equal h['f']['a'], 1
    assert_equal h['f']['b']['p'], 1
    assert_equal h['f']['b']['q'], 1
    assert_equal h['f']['c'], 1
  end

  def test_sort
    m = Redfish::Mash.new
    m['3'] = 1
    m['2'] = 's'
    m['1'] = true
    m['0'] = false
    m['a'] = 4.3
    m['c']['a'] = 1
    m['c']['b']['p'] = 2
    m['c']['b']['a'] = 3
    m['d'] = [1]

    m2 = m.sort

    # Make sure m has not changed
    h = m.to_h
    assert_equal h['3'], 1
    assert_equal h['2'], 's'
    assert_equal h['1'], true
    assert_equal h['0'], false
    assert_equal h['a'], 4.3
    assert_equal h['c']['a'], 1
    assert_equal h['c']['b']['p'], 2
    assert_equal h['c']['b']['a'], 3
    assert_equal h['d'], [1]

    assert_equal h.keys, %w(3 2 1 0 a c d)

    h = m2.to_h
    assert_equal h['3'], 1
    assert_equal h['2'], 's'
    assert_equal h['1'], true
    assert_equal h['0'], false
    assert_equal h['a'], 4.3
    assert_equal h['c']['a'], 1
    assert_equal h['c']['b']['p'], 2
    assert_equal h['c']['b']['a'], 3
    assert_equal h['d'], [1]

    assert_equal h.keys, %w(0 1 2 3 a c d)
  end
end
