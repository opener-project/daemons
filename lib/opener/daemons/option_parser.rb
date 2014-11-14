module Opener
  module Daemons
    ##
    # Slop wrapper for parsing daemon options and passing them to the underlying
    # script.
    #
    # @!attribute [r] name
    #  The name of the program to display in help messages.
    #  @return [String]
    #
    # @!attribute [r] parser
    #  @return [Slop]
    #
    class OptionParser
      attr_reader :name, :parser

      ##
      # @param [String] name
      #
      def initialize(name)
        @name   = name
        @parser = configure_slop
      end

      ##
      # @see [Slop#parse]
      #
      def parse(*args)
        return parser.parse(*args)
      end

      ##
      # @return [Slop]
      #
      def configure_slop
        # Slop uses instance_eval, which means `self` will point to the `Slop`
        # instance in the block below.
        outer       = self
        daemon_name = "#{name}-daemon"
        cli_name    = daemon_name.sub('opener-', '')

        # Using :strict => false ensures that unrecognized options are kept in
        # ARGV.
        return Slop.new(:strict => false, :indent => 2) do
          banner "Usage: #{cli_name} <start|stop|restart> [OPTIONS]"

          separator <<-EOF.chomp

About:

    Runs the OpeNER component as a daemon. By default the daemon runs in the
    foreground but using the "start" command it can detach itself. Output is
    logged using Syslog, allowing easy distribution and management of log
    output.

Commands:

    * start: starts the daemon in the background
    * stop: stops the daemon
    * restart: restarts the daemon

    Not providing a specific command will result in the daemon running in the
    foreground.

Environment Variables:

    These daemons make use of Amazon SQS queues and other Amazon services. In
    order to use these services you should make sure the following environment
    variables are set:

    * AWS_ACCESS_KEY_ID
    * AWS_SECRET_ACCESS_KEY
    * AWS_REGION

    If you're running this daemon on an EC2 instance then the first two
    environment variables will be set automatically if the instance has an
    associated IAM profile. The AWS_REGION variable must _always_ be set.

    Optionally you can also set the following extra variables:

    * NEWRELIC_TOKEN: when set the daemon will send profiling data to New Relic
      using this token. The application name will be "#{daemon_name}".

    * ROLLBAR_TOKEN: when set the daemon will report errors to Rollbar using
      this token. You can freely use this in combination with NEWRELIC_TOKEN.

Component Options:

    Certain OpeNER components might define their own commandline options. The
    most common one is the "--resource-path" option which can be used to load
    (and optionally download) a set of models and/or lexicons.

    Options that are not explicitly defined below will be passed straight to
    the component. Refer to the documentation of the individual components to
    see which options are available.
          EOF

          separator "\nOptions:\n"

          on :h, :help, 'Shows this help message' do
            abort to_s
          end

          on :i=,
            :input=,
            "The name of the input queue",
            :as      => String,
            :default => outer.name

          on :b=,
            :bucket=,
            'The S3 bucket to store output in',
            :as      => String,
            :default => outer.name

          on :P=,
            :pidfile=,
            "Path to the PID file",
            :as      => String,
            :default => "/var/run/opener/#{daemon_name}.pid"

          on :t=,
            :threads=,
            'The amount of threads to use',
            :as      => Integer,
            :default => 10

          on :w=,
            :wait=,
            'The amount of seconds to wait for the daemon to start',
            :as      => Integer,
            :default => 3

          on :'disable-syslog', 'Disables Syslog logging (enabled by default)'
        end
      end
    end # OptionParser
  end # Daemons
end # Opener
