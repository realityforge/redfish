require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestAuthRealm < Redfish::Tasks::BaseTaskTest
  def test_create_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-auth-realms'), equals(%w()), equals(:terse => true, :echo => false)).
      returns('')
    executor.expects(:exec).with(equals(t.context),
                                 equals('create-auth-realm'),
                                 equals(['--classname', 'com.sun.enterprise.security.auth.realm.file.FileRealm', '--property', 'assign-groups=SomeGroup:jaas-context=fileRealm:file=\\$\\{com\\.sun\\.aas\\.instanceRoot\\}\\/config\\/keyfile', 'MyAuthRealm']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-auth-realms'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyAuthRealm\n")
    # Return a property that should be deleted
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns('')

    expected_local_properties.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_create_element_where_cache_not_present_and_element_present_but_modified
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context), equals('list-auth-realms'), equals(%w()), equals(:terse => true, :echo => false)).
      returns("MyAuthRealm\n")
    # Return a property that should be deleted
    executor.expects(:exec).with(equals(t.context), equals('get'), equals(%W(#{property_prefix}property.*)), equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.Blah=Y\n")

    values = expected_local_properties
    values['property.assign-groups'] = 'SomeOtherGroup'

    values.each_pair do |k, v|
      executor.expects(:exec).with(equals(t.context),
                                   equals('get'),
                                   equals(["#{property_prefix}#{k}"]),
                                   equals(:terse => true, :echo => false)).
        returns("#{property_prefix}#{k}=#{v}\n")
    end

    executor.expects(:exec).with(equals(t.context),
                                 equals('get'),
                                 equals(["#{property_prefix}property.Blah"]),
                                 equals(:terse => true, :echo => false)).
      returns("#{property_prefix}property.Blah=X\n")

    # This is the set to remove property that should not exist
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.Blah="]),
                                 equals(:terse => true, :echo => false)).
      returns('')

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.assign-groups=SomeGroup"]),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
  end

  def test_create_element_where_cache_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties({})

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('create-auth-realm'),
                                 equals(['--classname', 'com.sun.enterprise.security.auth.realm.file.FileRealm', '--property', 'assign-groups=SomeGroup:jaas-context=fileRealm:file=\\$\\{com\\.sun\\.aas\\.instanceRoot\\}\\/config\\/keyfile', 'MyAuthRealm']),
                                 equals({})).
      returns('')

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)
    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present_but_modified
    cache_values = expected_properties

    executor = Redfish::Executor.new
    t = new_task(executor)

    cache_values["#{property_prefix}property.assign-groups"] = 'SomeOtherGroup'
    cache_values["#{property_prefix}property.DeleteMe"] = 'X'

    t.context.cache_properties(cache_values)

    t.options = resource_parameters

    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.assign-groups=SomeGroup"]),
                                 equals(:terse => true, :echo => false))
    executor.expects(:exec).with(equals(t.context),
                                 equals('set'),
                                 equals(["#{property_prefix}property.DeleteMe="]),
                                 equals(:terse => true, :echo => false))

    t.perform_action(:create)

    ensure_task_updated_by_last_action(t)

    ensure_expected_cache_values(t)
  end

  def test_create_element_where_cache_present_and_element_present
    t = new_task

    t.context.cache_properties(expected_properties)

    t.options = resource_parameters

    t.perform_action(:create)

    ensure_task_not_updated_by_last_action(t)

    ensure_expected_cache_values(t)
  end

  def test_delete_element_where_cache_not_present_and_element_not_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'MyAuthRealm'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-auth-realms'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_not_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.options = {'name' => 'MyAuthRealm'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('list-auth-realms'),
                                 equals([]),
                                 equals({:terse => true, :echo => false})).
      returns("MyAuthRealm\n")

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-auth-realm'),
                                 equals(['MyAuthRealm']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
  end

  def test_delete_element_where_cache_present_and_element_not_present
    t = new_task

    t.context.cache_properties({})
    t.options = {'name' => 'MyAuthRealm'}

    t.perform_action(:destroy)

    ensure_task_not_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  def test_delete_element_where_cache_present_and_element_present
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties(expected_properties)
    t.options = {'name' => 'MyAuthRealm'}

    executor.expects(:exec).with(equals(t.context),
                                 equals('delete-auth-realm'),
                                 equals(['MyAuthRealm']),
                                 equals({})).
      returns('')

    t.perform_action(:destroy)

    ensure_task_updated_by_last_action(t)
    ensure_properties_not_present(t)
  end

  protected

  def property_prefix
    'configs.config.server-config.security-service.auth-realm.MyAuthRealm.'
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    {
      'classname' => 'com.sun.enterprise.security.auth.realm.file.FileRealm',
      'property.assign-groups' => 'SomeGroup',
      'property.jaas-context' => 'fileRealm',
      'property.file' => '${com.sun.aas.instanceRoot}/config/keyfile'
    }
  end

  # Resource parameters
  def resource_parameters
    {
      'name' => 'MyAuthRealm',
      'classname' => 'com.sun.enterprise.security.auth.realm.file.FileRealm',
      'properties' => {
        'assign-groups' => 'SomeGroup',
        'jaas-context' => 'fileRealm',
        'file' => '${com.sun.aas.instanceRoot}/config/keyfile'
      }
    }
  end
end
