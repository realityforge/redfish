require File.expand_path('../helper', __FILE__)

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
end
