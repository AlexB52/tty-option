# frozen_string_literal: true

require_relative "deep_dup"
require_relative "dsl/arity"
require_relative "dsl/conversion"

module TTY
  module Option
    class Parameter
      include Comparable
      include DSL::Arity
      include DSL::Conversion

      # A parameter factory
      #
      # @api public
      def self.create(name, **settings, &block)
        new(name, **settings, &block)
      end

      attr_reader :name

      # Create a parameter
      #
      # @api private
      def initialize(name, **settings, &block)
        @name = name
        @settings = {}
        settings.each do |key, val|
          case key.to_sym
          when :arity
            val = check_arity(val)
          when :default
            val = check_default(val)
          when :optional
            key, val = :required, check_required(!val)
          when :permit
            val = check_permitted(val)
          when :validate
            val = check_validation(val)
          when :variable, :var
            key = :var
          end
          @settings[key.to_sym] = val
        end

        instance_eval(&block) if block_given?
      end

      def arity(value = (not_set = true))
        if not_set
          @settings.fetch(:arity) { default_arity }
        else
          @settings[:arity] = check_arity(value)
        end
      end

      def default_arity
        1
      end

      # Determine minimum boundary for arity parameter
      #
      # @api private
      def min_arity
        arity < 0 ? arity.abs - 1 : arity
      end

      # Check if multiple occurrences are allowed
      #
      # @return [Boolean]
      #
      # @api public
      def multiple?
        arity < 0 || 1 < arity.abs
      end

      def convert(value = (not_set = true))
        if not_set
          @settings[:convert]
        else
          @settings[:convert] = value
        end
      end

      def convert?
        @settings.key?(:convert) && !@settings[:convert].nil?
      end

      def default(value = (not_set = true))
        if not_set
          @settings[:default]
        else
          @settings[:default] = check_default(value)
        end
      end
      alias defaults default

      def default?
        @settings.key?(:default) && !@settings[:default].nil?
      end

      def desc(value = (not_set = true))
        if not_set
          @settings[:desc]
        else
          @settings[:desc] = value
        end
      end

      def desc?
        @settings.key?(:desc) && !@settings[:desc].nil?
      end

      # Check if this options is multi argument
      #
      # @api public
      def multi_argument?
        !convert.to_s.match(/list|array|map|hash|\w+s/).nil?
      end

      def optional
        @settings[:required] = false
      end

      def optional?
        !required?
      end

      def required
        @settings[:required] = check_required(true)
      end

      def required?
        @settings.fetch(:required) { false }
      end

      def hidden
        @settings[:hidden] = true
      end

      def hidden?
        @settings.fetch(:hidden) { false }
      end

      def display?
        desc? && !hidden?
      end

      def permit(value = (not_set = true))
        if not_set
          @settings[:permit]
        else
          @settings[:permit] = check_permitted(value)
        end
      end

      def permit?
        @settings.key?(:permit) && !@settings[:permit].nil?
      end

      def variable(value = (not_set = true))
        if not_set
          @settings.fetch(:var) { default_variable_name }
        else
          @settings[:var] = value
        end
      end
      alias var variable

      def default_variable_name
        name.to_s.tr("_", "-")
      end

      def validate(value = (not_set = true))
        if not_set
          @settings[:validate]
        else
          @settings[:validate] = check_validation(value)
        end
      end

      def validate?
        @settings.key?(:validate) && !@settings[:validate].nil?
      end

      def to_sym
        self.class.name.to_s.split(/::/).last.downcase.to_sym
      end

      # Compare this parameter name with the other
      #
      # @api public
      def <=>(other)
        name <=> other.name
      end

      # Compare parameters for equality based on type and name
      #
      # @api public
      def ==(other)
        return false unless instance_of?(other.class)
        name == other.name && to_h == other.to_h
      end

      # Compare parameters for equality based on type and name
      #
      # @api public
      def eql?(other)
        return false unless instance_of?(other.class)
        name.eql?(other.name) && to_h.eql?(other.to_h)
      end

      # Return a hash of this parameter settings
      #
      # @return [Hash] the names and values of this parameter
      #
      # @api public
      def to_h(&block)
        if block_given?
          @settings.each_with_object({}) do |(key, val), acc|
            k, v = *block.(key, val)
            acc[k] = v
          end
        else
          DeepDup.deep_dup(@settings)
        end
      end

      # Make a duplicate of this parameter
      #
      # @api public
      def dup
        super.tap do |param|
          param.instance_variable_set(:@name, DeepDup.deep_dup(@name))
          param.instance_variable_set(:@settings, DeepDup.deep_dup(@settings))
        end
      end

      private

      # @api private
      def check_arity(value)
        if value.nil?
          raise ConfigurationError,
                "#{to_sym} '#{variable}' arity needs to be an Integer"
        end

        case value.to_s
        when %r{\*|any} then value = -1
        when %r{\+}     then value = -2
        else value = value.to_i
        end

        if value.zero?
          raise ConfigurationError, "#{to_sym} '#{variable}' arity cannot be zero"
        end
        value
      end

      # @api private
      def check_permitted(value)
        if value.respond_to?(:include?)
          value
        else
          raise ConfigurationError,
                "#{to_sym} '#{variable}' permitted value needs to be an Array"
        end
      end

      def check_default(value)
        if !value.nil? && required?
          raise ConfigurationError,
                "#{to_sym} '#{variable}' cannot have default value and be required"
        else
          value
        end
      end

      # @api private
      def check_required(value)
        if value && default?
          raise ConfigurationError,
                "#{to_sym} '#{variable}' cannot be required and have default value"
        else
          value
        end
      end

      # @api private
      def check_validation(value)
        case value
        when NilClass
          raise ConfigurationError,
                "#{to_sym} '#{variable}' validation needs to be a Proc or a Regexp"
        when Proc
          value
        when Regexp, String
          Regexp.new(value.to_s)
        else
          raise ConfigurationError,
                "#{to_sym} '#{variable}' validation can only be a Proc or a Regexp"
        end
      end
    end # Parameter
  end # Option
end # TTY
