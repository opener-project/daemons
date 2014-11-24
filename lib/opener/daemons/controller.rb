module Opener
  module Daemons
    ##
    # CLI controller for a component.
    #
    # @!attribute [r] name
    #  The name of the daemon.
    #  @return [String]
    #
    # @!attribute [r] exec_path
    #  The path to the script to daemonize.
    #  @return [String]
    #
    # @!attribute [r] parser
    #  @return [Opener::Daemons::OptionParser]
    #
    class Controller
      attr_reader :name, :exec_path, :parser

      ##
      # @param [Hash] options
      #
      # @option options [String] :name
      # @option options [String] :exec_path
      #
      def initialize(options = {})
        @name      = options.fetch(:name)
        @exec_path = options.fetch(:exec_path)
        @parser    = configure_slop
      end

      ##
      # Runs the CLI
      #
      # @param [Array] argv CLI arguments to parse.
      #
      def run(argv = ARGV)
        parser.parse(argv)
      end

      ##
      # @return [Slop]
      #
      def configure_slop
        parser = OptionParser.new(name)

        parser.parser.run do |opts, args|
          command  = args.shift
          new_args = args.reject { |arg| arg == '--' }

          case command
          when 'start'
            start_background(opts, new_args)
          when 'stop'
            stop(opts)
          when 'restart'
            stop(opts)
            start_background(opts, new_args)
          else
            start_foreground(opts, new_args)
          end
        end

        return parser
      end

      ##
      # Runs the daemon in the foreground.
      #
      # @param [Slop] options
      # @param [Array] argv
      #
      def start_foreground(options, argv = [])
        exec(setup_env(options), exec_path, *argv)
      end

      ##
      # Starts the daemon in the background.
      #
      # @param [Slop] options
      # @param [Array] argv
      #
      def start_background(options, argv = [])
        pidfile = Pidfile.new(options[:pidfile])
        pid     = Process.spawn(
          setup_env(options),
          exec_path,
          *argv,
          :out => :close,
          :err => :close,
          :in  => :close
        )

        pidfile.write(pid)

        begin
          # Wait until the process has _actually_ started.
          Timeout.timeout(options[:wait]) { sleep(0.5) until pidfile.alive? }

          puts "Process with Pidfile #{pidfile.read} started"
        rescue Timeout::Error
          pidfile.unlink

          abort "Failed to start the process after #{options[:wait]} seconds"
        end
      end

      ##
      # Stops the daemon.
      #
      # @param [Slop] options
      #
      def stop(options)
        pidfile = Pidfile.new(options[:pidfile])

        if pidfile.alive?
          id = pidfile.read

          pidfile.terminate
          pidfile.unlink

          puts "Process with Pidfile #{id.inspect} terminated"
        else
          abort 'Process already terminated or you are not allowed to terminate it'
        end
      end

      ##
      # Returns a Hash containing the various environment variables to set for
      # the daemon (on top of the current environment variables).
      #
      # @param [Slop] options
      # @return [Hash]
      #
      def setup_env(options)
        newrelic_config = File.expand_path(
          '../../../../config/newrelic.yml',
          __FILE__
        )

        env = ENV.to_hash.merge(
          'INPUT_QUEUE'    => options[:input].to_s,
          'DAEMON_THREADS' => options[:threads].to_s,
          'OUTPUT_BUCKET'  => options[:bucket].to_s,
          'NRCONFIG'       => newrelic_config,
          'APP_ROOT'       => File.expand_path('../../../../', __FILE__),
          'APP_NAME'       => name
        )

        if !env['RAILS_ENV'] and env['RACK_ENV']
          env['RAILS_ENV'] = env['RACK_ENV']
        end

        unless options[:'disable-syslog']
          env['ENABLE_SYSLOG'] = 'true'
        end

        return env
      end
    end # Controller
  end # Daemons
end # Opener
