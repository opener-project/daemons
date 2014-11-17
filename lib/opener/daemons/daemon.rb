module Opener
  module Daemons
    ##
    # The Daemon class communicates with an AWS SQS queue and delegates work to
    # the mapper and worker classes.
    #
    # @!attribute [r] component
    #  @return [Class]
    #
    # @!attribute [r] component_options
    #  @return [Hash]
    #
    class Daemon < Oni::Daemons::SQS
      attr_reader :component, :component_options

      set :worker, Worker
      set :mapper, Mapper

      # The name of the SQS input queue to use.
      set :queue_name, proc { Daemons.input_queue }

      # The amount of threads to use.
      set :threads, proc { Daemons.daemon_threads }

      ##
      # @param [Class] component The component to run in the worker.
      # @param [Hash] options Extra options to pass to the component.
      #
      def initialize(component, options = {})
        @component         = component
        @component_options = options

        super() # keep parenthesis, parent method doesn't take arguments.
      end

      ##
      # Called before the daemon is started.
      #
      def before_start
        Syslog.open(ENV['APP_NAME'], ::Syslog::LOG_CONS | ::Syslog::LOG_PID)

        Syslog.info(
          'Starting daemon',
          :queue   => option(:queue_name),
          :threads => threads
        )

        GC::Profiler.enable

        Daemons.configure_rollbar

        NewRelic::Agent.manual_start if Daemons.newrelic?
      end

      ##
      # Overwrites the original method so that we can inject the component into
      # the mapper.
      #
      # @see [Oni::Daemon#create_mapper]
      #
      def create_mapper
        unless option(:mapper)
          raise ArgumentError, 'No mapper has been set in the `:mapper` option'
        end

        return option(:mapper).new(component, component_options)
      end

      ##
      # Called when an error occurs.
      #
      # @param [StandardError] error
      #
      def error(error)
        error, params = unwrap_error(error)

        report_exception(error, params)
      end

      ##
      # @param [AWS::SQS::ReceivedMessage] message
      # @param [Mixed] output
      # @param [Benchmark::Tms] timings
      #
      def complete(message, output, timings)
        log_msg = "Finished message #{message.id}"

        Syslog.info(log_msg)
      end

      ##
      # Sends an error to Rollbar.
      #
      # @param [StandardError] error
      # @param [Hash] parameters
      #
      def report_exception(error, parameters = {})
        if Daemons.rollbar?
          Rollbar.error(
            error,
            :active_threads   => Thread.list.count,
            :ruby_description => RUBY_DESCRIPTION,
            :parameters       => parameters
          )
        else
          raise error
        end
      end

      ##
      # Takes either a regular error or a `Oni::WrappedError` and unwraps it,
      # returning the original error and the parameters (if any).
      #
      # @param [StandardError] error
      # @return [Array]
      #
      def unwrap_error(error)
        params = error.respond_to?(:parameters) ? error.parameters : {}
        error  = error.original_error if error.respond_to?(:original_error)

        return error, params
      end
    end # Daemon
  end # Daemons
end # Opener
