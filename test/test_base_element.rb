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

class Redfish::TestBaseElement < Redfish::TestCase
  class TestElement < Redfish::BaseElement
    attr_accessor :a
    attr_accessor :b
    attr_accessor :c

    def to_s
      'TestElement'
    end
  end

  def test_basic_operation
    element1 = TestElement.new do |e|
      e.a = 1
      e.b = 2
      e.c = 3
    end
    assert_equal 1, element1.a
    assert_equal 2, element1.b
    assert_equal 3, element1.c

    element2 = TestElement.new(:a => '1', :b => '2', 'c' => '3') do |e|
      e.a = 1
    end
    assert_equal 1, element2.a
    assert_equal '2', element2.b
    assert_equal '3', element2.c

    error = assert_raises(RuntimeError) do
      TestElement.new(:x => '1')
    end
    assert_equal 'Attempted to configure property "x" on Redfish::TestBaseElement::TestElement but property does not exist.', error.message
  end

  class TestElementA < Redfish.base_element
  end

  class TestElementB < Redfish.base_element(:container_key => 'container')
  end

  class TestElementC < Redfish.base_element(:name => true)
  end

  class TestElementD < Redfish.base_element(:key => true)
  end

  class TestElementE < Redfish.base_element(:name => true, :key => true)
  end

  class TestElementF < Redfish.base_element(:container_key => 'container', :name => true, :key => true)
  end

  class TestElementG < Redfish.base_element(:pre_config_code => 'self.foo = 1')
    attr_accessor :foo
  end

  def test_base_element_constructor
    e = TestElementA.new
    assert_raises(NoMethodError) { e.key }
    assert_raises(NoMethodError) { e.name }

    e = TestElementB.new('FakeContainer')
    assert_raises(NoMethodError) { e.key }
    assert_raises(NoMethodError) { e.name }
    assert_equal e.container, 'FakeContainer'

    e = TestElementC.new('myName')
    assert_raises(NoMethodError) { e.key }
    assert_equal e.name, 'myName'

    e = TestElementD.new('myKey')
    assert_raises(NoMethodError) { e.name }
    assert_equal e.key, 'myKey'

    e = TestElementE.new('myKey', 'myName')
    assert_equal e.key, 'myKey'
    assert_equal e.name, 'myName'

    e = TestElementF.new('FakeContainer', 'myKey', 'myName')
    assert_equal e.container, 'FakeContainer'
    assert_equal e.key, 'myKey'
    assert_equal e.name, 'myName'

    TestElementG.new do |te|
      assert_equal te.foo, 1
    end
  end
end
