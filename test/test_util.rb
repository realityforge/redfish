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

class Redfish::TestUtil < Redfish::TestCase

  def test_generate_password
    password = Redfish::Util.generate_password
    assert_equal password.size, 10
    assert_equal password.gsub(/[A-Za-z0-9]/,''), ''
  end

  def test_underscore
    assert_equal Redfish::Util.underscore('thisIsCamelCased'), 'this_is_camel_cased'
    assert_equal Redfish::Util.underscore('ThisIsCamelCased'), 'this_is_camel_cased'
    assert_equal Redfish::Util.underscore('this_Is_Camel_Cased'), 'this_is_camel_cased'
    assert_equal Redfish::Util.underscore('this_Is_camel_cased'), 'this_is_camel_cased'
    assert_equal Redfish::Util.underscore('EJB'), 'ejb'
    assert_equal Redfish::Util.underscore('EJBContainer'), 'ejb_container'
    assert_equal Redfish::Util.underscore('_someField'), 'some_field'
  end

  def test_uppercase_constantize
    assert_equal Redfish::Util.uppercase_constantize('thisIsCamelCased'), 'THIS_IS_CAMEL_CASED'
    assert_equal Redfish::Util.uppercase_constantize('ThisIsCamelCased'), 'THIS_IS_CAMEL_CASED'
    assert_equal Redfish::Util.uppercase_constantize('this_Is_Camel_Cased'), 'THIS_IS_CAMEL_CASED'
    assert_equal Redfish::Util.uppercase_constantize('this_Is_camel_cased'), 'THIS_IS_CAMEL_CASED'
    assert_equal Redfish::Util.uppercase_constantize('EJB'), 'EJB'
    assert_equal Redfish::Util.uppercase_constantize('EJBContainer'), 'EJB_CONTAINER'
    assert_equal Redfish::Util.uppercase_constantize('_someField'), 'SOME_FIELD'
  end

  def test_naming_conversions_accept_symbols_and_dashes
    assert_equal Redfish::Util.underscore('MySupportLibrary'), 'my_support_library'
    assert_equal Redfish::Util.underscore('my_support_library'), 'my_support_library'
    assert_equal Redfish::Util.underscore('my-support-library'), 'my_support_library'
    assert_equal Redfish::Util.underscore(:'MySupportLibrary'), 'my_support_library'
    assert_equal Redfish::Util.underscore(:'my_support_library'), 'my_support_library'
    assert_equal Redfish::Util.underscore(:'my-support-library'), 'my_support_library'

    assert_equal Redfish::Util.uppercase_constantize('MySupportLibrary'), 'MY_SUPPORT_LIBRARY'
    assert_equal Redfish::Util.uppercase_constantize('my_support_library'), 'MY_SUPPORT_LIBRARY'
    assert_equal Redfish::Util.uppercase_constantize('my-support-library'), 'MY_SUPPORT_LIBRARY'
    assert_equal Redfish::Util.uppercase_constantize(:'MySupportLibrary'), 'MY_SUPPORT_LIBRARY'
    assert_equal Redfish::Util.uppercase_constantize(:'my_support_library'), 'MY_SUPPORT_LIBRARY'
    assert_equal Redfish::Util.uppercase_constantize(:'my-support-library'), 'MY_SUPPORT_LIBRARY'
  end
end
