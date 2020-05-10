# frozen_string_literal: true

require_relative "option/conversions"
require_relative "option/dsl"
require_relative "option/errors"
require_relative "option/parser"
require_relative "option/formatter"
require_relative "option/version"

module TTY
  module Option
    # Enhance object with command line option parsing
    #
    # @api public
    def self.included(base)
      base.module_eval do
        include Interface
        extend DSL
        extend Inheritance
      end
    end

    module Inheritance
      # When class is inherited copy over parameter definitions
      # This allows for definition of global parameters without
      # affecting child class parameters and vice versa.
      def inherited(subclass)
        subclass.instance_variable_set(:@parameters, @parameters.dup)
        super
      end
    end

    module Interface
      # The parsed parameters
      #
      # @api public
      def parameters
        @parameters ||= {}
      end
      alias :params :parameters

      # The remaining unparsed arguments
      #
      # @api public
      def remaining
        @remaining ||= []
      end
      alias :remaining_args :remaining

      # The parsing errors
      #
      # @api public
      def errors
        @errors ||= {}
      end

      # Parse command line arguments
      #
      # @param [Array<String>] argv
      #   the command line arguments
      # @param [Hash] env
      #   the hash of environment variables
      #
      # @api public
      def parse(argv = ARGV, env = ENV, **config)
        parser = Parser.new(self.class.parameters, **config)
        @parameters, @remaining, @errors = parser.parse(argv, env)
      end

      # Provide a formatted help usage for the configured parameters
      #
      # @return [String]
      #
      # @api public
      def help(**config, &block)
        Formatter.help(self.class.parameters, self.class.usage, **config, &block)
      end
    end
  end # Option
end # TTY
