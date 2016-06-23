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

module Redfish
  module Tasks
    module Glassfish
      class JdbcConnectionPool < BaseResourceTask
        PROPERTY_PREFIX = 'resources.jdbc-connection-pool.'

        private

        JdbcAttribute = Struct.new('JdbcAttribute', :key, :type, :arg, :default_value, :options)

        ATTRIBUTES = []

        def self.str(key, arg, default_value = '', options = {})
          ATTRIBUTES << JdbcAttribute.new(key, :string, arg, default_value, options)
        end

        def self.num(key, arg, default_value = 0, options = {})
          ATTRIBUTES << JdbcAttribute.new(key, :numeric, arg, default_value, options)
        end

        def self.bool(key, arg, default_value = true, options = {})
          ATTRIBUTES << JdbcAttribute.new(key, :boolean, arg, default_value, options)
        end

        def self.opt(key, arg, values, default_value, options = {})
          ATTRIBUTES << JdbcAttribute.new(key, values, arg, default_value, options)
        end

        str(:datasourceclassname, 'datasource-classname')
        str(:initsql, 'init-sql')
        str(:sqltracelisteners, 'sql-trace-listeners')
        str(:driverclassname, 'driver-classname')
        str(:validationclassname, 'validation-classname')
        str(:validationtable, 'validation-table-name')

        num(:steadypoolsize, 'steady-pool-size', 8)
        num(:maxpoolsize, 'max-pool-size', 32)
        num(:maxwait, 'max-wait-time-in-millis', 60000)
        num(:poolresize, 'pool-resize-quantity', 2)
        num(:idletimeout, 'idle-timeout-in-seconds', 300)
        num(:validateatmostonceperiod, 'validate-atmost-once-period-in-seconds')
        num(:leaktimeout, 'connection-leak-timeout-in-seconds')
        num(:statementleaktimeout, 'statement-leak-timeout-in-seconds')
        num(:creationretryattempts, 'connection-creation-retry-attempts')
        num(:creationretryinterval, 'connection-creation-retry-interval-in-seconds', 10)
        num(:statementtimeout, 'statement-timeout-in-seconds', -1)
        num(:maxconnectionusagecount, 'max-connection-usage-count')
        num(:statementcachesize, 'statement-cache-size')

        bool(:isisolationguaranteed, 'is-isolation-level-guaranteed')
        bool(:isconnectvalidatereq, 'is-connection-validation-required')
        bool(:failconnection, 'fail-all-connections', false)
        bool(:allownoncomponentcallers, 'allow-non-component-callers', false)
        bool(:nontransactionalconnections, 'non-transactional-connections', false)
        bool(:statementleakreclaim, 'statement-leak-reclaim', false)
        bool(:leakreclaim, 'connection-leak-reclaim', false)
        bool(:lazyconnectionenlistment, 'lazy-connection-enlistment', false)
        bool(:lazyconnectionassociation, 'lazy-connection-association', false)
        bool(:associatewiththread, 'associate-with-thread', false)
        bool(:matchconnections, 'match-connections', false)
        bool(:ping, 'ping')
        bool(:pooling, 'pooling')
        bool(:wrapjdbcobjects, 'wrap-jdbc-objects')

        opt(:restype,
            'res-type',
            %w(java.sql.Driver javax.sql.DataSource javax.sql.XADataSource javax.sql.ConnectionPoolDataSource),
            nil)
        opt(:isolationlevel,
            'transaction-isolation-level',
            %w(read-uncommitted read-committed repeatable-read serializable),
            nil)
        opt(:validationmethod,
            'connection-validation-method',
            %w(auto-commit meta-data table custom-validation),
            'auto-commit')

        attribute :name, :kind_of => String, :required => true, :identity_field => true
        attribute :description, :kind_of => String, :default => ''
        attribute :properties, :kind_of => Hash, :default => {}
        attribute :deployment_order, :kind_of => Fixnum, :default => 100

        ATTRIBUTES.each do |attr|
          if attr.type == :string
            attribute attr.key, attr.options.merge(:kind_of => String, :default => attr.default_value)
          elsif attr.type == :numeric
            attribute attr.key, attr.options.merge(:type => :integer, :default => attr.default_value)
          elsif attr.type == :boolean
            attribute attr.key, attr.options.merge(:type => :boolean, :default => attr.default_value)
          elsif attr.type.is_a?(Array)
            attribute attr.key, attr.options.merge(:equal_to => attr.type, :default => attr.default_value)
          end
        end

        attribute :log_jdbc_calls, :type => :boolean, :default => false
        attribute :slow_query_threshold_in_seconds, :type => :integer, :default => -1

        action :create do
          create(resource_property_prefix)
        end

        action :destroy do
          destroy(resource_property_prefix)
        end

        def resource_property_prefix
          "#{PROPERTY_PREFIX}#{self.name}."
        end

        def properties_to_record_in_create
          # statement-cache-type, log-jdbc-calls, slow-query-threshold-in-seconds do not seem to be configurable
          # during create, this sets to defaults and may be explicitly set.
          {
            'object-type' => 'user',
            'name' => self.name,
            'deployment-order' => '100',
            'statement-cache-type' => '',
            'log-jdbc-calls' => 'false',
            'slow-query-threshold-in-seconds' => '-1'
          }
        end

        def properties_to_set_in_create
          property_map = {}

          collect_property_sets(resource_property_prefix, property_map)

          ATTRIBUTES.each do |attr|
            property_map[attr.arg] = self.send(attr.key)
          end

          property_map['description'] = self.description

          property_map
        end

        def properties_to_always_set
          if self.domain_version.support_log_jdbc_calls?
            {
              'log-jdbc-calls' => self.log_jdbc_calls.to_s,
              'slow-query-threshold-in-seconds' => self.slow_query_threshold_in_seconds.to_s
            }
          else
            {}
          end
        end

        def do_create
          args = []
          ATTRIBUTES.each do |attr|
            args << "--#{attr.key}=#{self.send(attr.key)}"
          end

          args << '--property' << encode_parameters(self.properties) unless self.properties.empty?
          args << '--description' << self.description
          args << self.name

          context.exec('create-jdbc-connection-pool', args)
        end

        def do_destroy
          args = []
          args << '--cascade=true'
          args << self.name
          context.exec('delete-jdbc-connection-pool', args)
        end

        def add_resource_ref?
          false
        end

        def present?
          (context.exec('list-jdbc-connection-pools', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
        end
      end
    end
  end
end
