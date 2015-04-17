require File.expand_path('../helper', __FILE__)

class Redfish::TestNaming < Redfish::TestCase

  def test_basics
    assert_equal Redfish::Naming.camelize('thisIsCamelCased'), 'thisIsCamelCased'
    assert_equal Redfish::Naming.camelize('ThisIsCamelCased'), 'thisIsCamelCased'
    assert_equal Redfish::Naming.camelize('this_Is_Camel_Cased'), 'thisIsCamelCased'
    assert_equal Redfish::Naming.camelize('this_Is_camel_cased'), 'thisIsCamelCased'
    assert_equal Redfish::Naming.camelize('EJB'), 'ejb'
    assert_equal Redfish::Naming.camelize('EJBContainer'), 'ejbContainer'

    assert_equal Redfish::Naming.pascal_case('thisIsCamelCased'), 'ThisIsCamelCased'
    assert_equal Redfish::Naming.pascal_case('ThisIsCamelCased'), 'ThisIsCamelCased'
    assert_equal Redfish::Naming.pascal_case('this_Is_Camel_Cased'), 'ThisIsCamelCased'
    assert_equal Redfish::Naming.pascal_case('this_Is_camel_cased'), 'ThisIsCamelCased'
    assert_equal Redfish::Naming.pascal_case('EJB'), 'Ejb'
    assert_equal Redfish::Naming.pascal_case('EJBContainer'), 'EjbContainer'

    assert_equal Redfish::Naming.underscore('thisIsCamelCased'), 'this_is_camel_cased'
    assert_equal Redfish::Naming.underscore('ThisIsCamelCased'), 'this_is_camel_cased'
    assert_equal Redfish::Naming.underscore('this_Is_Camel_Cased'), 'this_is_camel_cased'
    assert_equal Redfish::Naming.underscore('this_Is_camel_cased'), 'this_is_camel_cased'
    assert_equal Redfish::Naming.underscore('EJB'), 'ejb'
    assert_equal Redfish::Naming.underscore('EJBContainer'), 'ejb_container'

    assert_equal Redfish::Naming.uppercase_constantize('thisIsCamelCased'), 'THIS_IS_CAMEL_CASED'
    assert_equal Redfish::Naming.uppercase_constantize('ThisIsCamelCased'), 'THIS_IS_CAMEL_CASED'
    assert_equal Redfish::Naming.uppercase_constantize('this_Is_Camel_Cased'), 'THIS_IS_CAMEL_CASED'
    assert_equal Redfish::Naming.uppercase_constantize('this_Is_camel_cased'), 'THIS_IS_CAMEL_CASED'
    assert_equal Redfish::Naming.uppercase_constantize('EJB'), 'EJB'
    assert_equal Redfish::Naming.uppercase_constantize('EJBContainer'), 'EJB_CONTAINER'

    assert_equal Redfish::Naming.xmlize('thisIsCamelCased'), 'this-is-camel-cased'
    assert_equal Redfish::Naming.xmlize('ThisIsCamelCased'), 'this-is-camel-cased'
    assert_equal Redfish::Naming.xmlize('this_Is_Camel_Cased'), 'this-is-camel-cased'
    assert_equal Redfish::Naming.xmlize('this_Is_camel_cased'), 'this-is-camel-cased'
    assert_equal Redfish::Naming.xmlize('EJB'), 'ejb'
    assert_equal Redfish::Naming.xmlize('EJBContainer'), 'ejb-container'

    assert_equal Redfish::Naming.jsonize('thisIsCamelCased'), 'thisIsCamelCased'
    assert_equal Redfish::Naming.jsonize('ThisIsCamelCased'), 'thisIsCamelCased'
    assert_equal Redfish::Naming.jsonize('this_Is_Camel_Cased'), 'thisIsCamelCased'
    assert_equal Redfish::Naming.jsonize('this_Is_camel_cased'), 'thisIsCamelCased'
    assert_equal Redfish::Naming.jsonize('EJB'), 'ejb'
    assert_equal Redfish::Naming.jsonize('EJBContainer'), 'ejbContainer'
  end
end
