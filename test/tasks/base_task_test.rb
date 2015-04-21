require File.expand_path('../../helper', __FILE__)

class Redfish::Tasks::BaseTaskTest < Redfish::TestCase

  protected

  def ensure_task_updated_by_last_action(task)
    assert_equal task.updated_by_last_action?, true
  end

  def ensure_task_not_updated_by_last_action(task)
    assert_equal task.updated_by_last_action?, false
  end

  def ensure_properties_not_present(task)
    assert_equal task.context.property_cache.any_property_start_with?(property_prefix), false
  end

  def ensure_expected_cache_values(t)
    expected_properties.each_pair do |key, value|
      assert_equal t.context.property_cache[key], value, "Expected #{key}=#{value}"
    end
  end

  def property_prefix
    raise 'property_prefix not overridden'
  end

  def expected_properties
    cache_values = {}

    expected_local_properties.each_pair do |k, v|
      cache_values["#{property_prefix}#{k}"] = "#{v}"
    end
    cache_values
  end

  # Properties in GlassFish properties directory
  def expected_local_properties
    raise 'expected_local_properties not overridden'
  end

  # Resource parameters
  def resource_parameters
    raise 'resource_parameters not overridden'
  end

  def new_task(executor = Redfish::Executor.new)
    task_name = self.class.name.to_s.split('::').last.gsub(/^Test/,'')
    p task_name
    t = Redfish::Tasks.const_get(task_name).new
    t.context = create_simple_context(executor)
    t
  end
end
