module Redfish
  module Tasks
    class JdbcConnectionPool < BaseResourceTask

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

      public

      attribute :name, :kind_of => String, :required => true
      attribute :description, :kind_of => String, :default => ''
      attribute :properties, :kind_of => Hash, :default => {}
      attribute :deploymentorder, :kind_of => Fixnum, :default => 100

      ATTRIBUTES.each do |attr|
        if attr.type == :string
          attribute attr.key, attr.options.merge(:kind_of => String, :default => attr.default_value)
        elsif attr.type == :numeric
          attribute attr.key, attr.options.merge(:kind_of => [Fixnum, String], :regex => /^[0-9]+$/, :default => attr.default_value)
        elsif attr.type == :boolean
          attribute attr.key, attr.options.merge(:equal_to => [true, false, 'true', 'false'], :default => attr.default_value)
        elsif attr.type.is_a?(Array)
          attribute attr.key, attr.options.merge(:equal_to => attr.type, :default => attr.default_value)
        end
      end

      action :create do
        create(resource_property_prefix)
      end

      action :destroy do
        destroy(resource_property_prefix)
      end

      def resource_property_prefix
        "resources.jdbc-connection-pool.#{self.name}."
      end

      def properties_to_record_in_create
        {'object-type' => 'user', 'name' => self.name, 'deployment-order' => '100'}
      end

      def properties_to_set_in_create
        property_map = {'description' => self.description}
        collect_property_sets(resource_property_prefix, property_map)

        ATTRIBUTES.each do |attr|
          property_map[attr.arg] = self.send(attr.key)
        end
        property_map
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

      def present?
        (context.exec('list-jdbc-connection-pools', [], :terse => true, :echo => false) =~ /^#{Regexp.escape(self.name)}$/)
      end
    end
  end
end
