require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::TestProperty < Redfish::Tasks::BaseTaskTest
  def test_property_no_cache_and_not_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),equals('get'),equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping)),equals(:terse => true, :echo => false)).returns('')
    executor.expects(:exec).with(equals(t.context),equals('set'),equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true)),equals(:terse => true, :echo => false)).returns('')

    t.key = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
  end

  def test_property_no_cache_and_already_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    executor.expects(:exec).with(equals(t.context),equals('get'),equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping)),equals(:terse => true, :echo => false)).returns('configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true')

    t.key = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    ensure_task_not_updated_by_last_action(t)
  end

  def test_property_cache_and_not_set
    executor = Redfish::Executor.new
    t = new_task(executor)

    t.context.cache_properties('configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'false')

    executor.expects(:exec).with(equals(t.context),equals('set'),equals(%w(configs.config.server-config.security-service.activate-default-principal-to-role-mapping=true)),equals(:terse => true, :echo => false)).returns('')

    t.key = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    ensure_task_updated_by_last_action(t)
    assert_equal t.context.property_cache['configs.config.server-config.security-service.activate-default-principal-to-role-mapping'], 'true'
  end

  def test_property_cache_and_set
    t = new_task

    t.context.cache_properties('configs.config.server-config.security-service.activate-default-principal-to-role-mapping' => 'true')

    t.key = 'configs.config.server-config.security-service.activate-default-principal-to-role-mapping'
    t.value = 'true'
    t.perform_action(:set)

    ensure_task_not_updated_by_last_action(t)
  end
end
