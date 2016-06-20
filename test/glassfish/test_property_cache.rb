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

require File.expand_path('../../helper', __FILE__)

class Redfish::TestPropertyCache < Redfish::TestCase
  def test_properties_are_duplicated
    input_data = {'a' => '1', 'b' => '2'}

    cache = Redfish::PropertyCache.new(input_data)

    # Data should be identical
    assert_equal cache.properties, input_data

    # Ensure input can not be modified to modify cache
    input_data['a'] = '3'
    assert_equal cache['a'], '1'

    # Ensure cache does not modify input
    cache['b'] = '4'
    assert_equal input_data['b'], '2'

    # properties accessor does a dup
    cache.properties['b'] = '5'
    assert_equal cache['b'], '4'
  end

  def test_any_property_start_with?
    cache = Redfish::PropertyCache.new('a.b.c' => '1', 'a.b.d' => '2', 'a.c.e' => '2', 'xx' => '2')

    assert cache.any_property_start_with?('a.b')
    assert cache.any_property_start_with?('a.b.d')
    assert !cache.any_property_start_with?('x.')
    assert cache.any_property_start_with?('x')
  end

  def test_delete_all_with_prefix!

    cache = Redfish::PropertyCache.new('a.b.c' => '1', 'a.b.d' => '2', 'a.c.e' => '2', 'xx' => '2')

    cache.delete_all_with_prefix!('a.c.f')

    assert_equal cache.properties, {'a.b.c' => '1', 'a.b.d' => '2', 'a.c.e' => '2', 'xx' => '2'}

    cache.delete_all_with_prefix!('xx')

    assert_equal cache.properties, {'a.b.c' => '1', 'a.b.d' => '2', 'a.c.e' => '2'}

    cache.delete_all_with_prefix!('a.c.f')

    assert_equal cache.properties, {'a.b.c' => '1', 'a.b.d' => '2', 'a.c.e' => '2'}

    cache.delete_all_with_prefix!('a.c')

    assert_equal cache.properties, {'a.b.c' => '1', 'a.b.d' => '2'}

    cache.delete_all_with_prefix!('a')

    assert_equal cache.properties, {}
  end

  def test_get_keys_starting_with
    cache = Redfish::PropertyCache.new('a.b.c' => '1', 'a.b.d' => '2', 'a.c.e' => '2', 'xx' => '2')

    assert_equal cache.get_keys_starting_with('a.c.').sort, %w(a.c.e)
    assert_equal cache.get_keys_starting_with('a').sort, %w(a.b.c a.b.d a.c.e)
    assert_equal cache.get_keys_starting_with('zz').sort, []
  end
end
