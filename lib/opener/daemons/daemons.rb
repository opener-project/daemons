module Opener
  module Daemons
    ##
    # Returns `true` if New Relic monitoring should be enabled.
    #
    # @return [TrueClass|FalseClass]
    #
    def self.newrelic?
      return !!ENV['NEWRELIC_TOKEN']
    end

    ##
    # Returns `true` if Rollbar error tracking should be enabled.
    #
    # @return [TrueClass|FalseClass]
    #
    def self.rollbar?
      return !!ENV['ROLLBAR_TOKEN']
    end

    ##
    # Returns `true` if Syslog should be enabled.
    #
    # @return [TrueClass|FalseClass]
    #
    def self.syslog?
      return !!ENV['ENABLE_SYSLOG']
    end

    ##
    # Returns the name of the input queue to use.
    #
    # @return [String]
    #
    def self.input_queue
      return ENV['INPUT_QUEUE']
    end

    ##
    # The name of the S3 bucket to store output in.
    #
    # @return [String]
    #
    def self.output_bucket
      return ENV['OUTPUT_BUCKET']
    end

    ##
    # Returns the amount of daemon threads to run.
    #
    # @return [Fixnum]
    #
    def self.daemon_threads
      return ENV['DAEMON_THREADS'].to_i
    end

    ##
    # Configures Rollbar.
    #
    def self.configure_rollbar
      Rollbar.configure do |config|
        config.access_token = ENV['ROLLBAR_TOKEN']
        config.enabled      = rollbar?
        config.environment  = environment
      end
    end

    ##
    # @return [String]
    #
    def self.environment
      return ENV['DAEMON_ENV'] || ENV['RACK_ENV'] || ENV['RAILS_ENV']
    end
  end # Daemons
end # Opener
