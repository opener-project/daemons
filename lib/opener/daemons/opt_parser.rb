require 'optparse'

module Opener
  module Daemons
    class OptParser
      attr_accessor :option_parser, :options

      def initialize(&block)
        @options = {}
        @option_parser = construct_option_parser(options, &block)
      end

      def parse(args)
        process(:parse, args)
      end

      def parse!(args)
        process(:parse!, args)
      end

      def pre_parse!(args)
        delete_double_dash = false
        process(:parse!, args, delete_double_dash)
      end

      def pre_parse(args)
        delete_double_dash = false
        process(:parse, args, delete_double_dash)
      end

      def self.parse(args)
        new.parse(args)
      end

      def self.parse!(args)
        new.parse!(args)
      end

      def self.pre_parse!(args)
        new.pre_parse!(args)
      end

      def self.pre_parse(args)
        new.pre_parse(args)
      end

      private

      def process(call, args, delete_double_dash=true)
        args.delete("--") if delete_double_dash
        option_parser.send(call, args)
        return options
      end

      def construct_option_parser(options, &block)
        script_name = File.basename($0, ".rb")

        OptionParser.new do |opts|
          if block_given?
            opts.banner = "Usage: #{script_name} <start|stop|restart> [daemon_options] -- [component_options]"
          else
            opts.banner = "Usage: #{script_name} <start|stop|restart> [options]"
          end

          opts.separator ""
          opts.separator "When calling #{script_name} without <start|stop|restart> the daemon will start as a foreground process"
          opts.separator ""

          if block_given?
            opts.separator "Component Specific options:"
            opts.separator ""
            yield opts, options
            opts.separator ""
          end

          opts.separator "Daemon options:"

          opts.on("-i", "--input QUEUE_NAME", "Input queue name") do |v|
            options[:input_queue] = v
          end

          opts.on("-o", "--output QUEUE_NAME", "Output queue name") do |v|
            options[:output_queue] = v
          end

          opts.on("--batch-size COUNT", Integer, "Request x messages at once where x is between 1 and 10") do |v|
            options[:batch_size] = v
          end

          opts.on("--buffer-size COUNT", Integer, "Size of input and output buffer. Defaults to 4 * batch-size") do |v|
            options[:buffer_size] = v
          end

          opts.on("--sleep-interval SECONDS", Integer, "The interval to sleep when the queue is empty (seconds)") do |v|
            options[:sleep_interval] = v
          end

          opts.on("-r", "--readers COUNT", Integer, "number of reader threads") do |v|
            options[:readers] = v
          end

          opts.on("-w", "--workers COUNT", Integer, "number of worker thread") do |v|
            options[:workers] = v
          end

          opts.on("-p", "--writers COUNT", Integer, "number of writer / pusher threads") do |v|
            options[:writers] = v
          end

          opts.on("-l", "--logfile FILENAME", "--log FILENAME", "Filename and path of logfile. Defaults to STDOUT") do |v|
            options[:log] = v
          end

          opts.on("-P", "--pidfile FILENAME", "--pid FILENAME", "Filename and path of pidfile. Defaults to /var/run/#{script_name}.pid") do |v|
            options[:pid] = v
          end

          opts.on("--pidpath DIRNAME", "Directory where to put the PID file. Is Overwritten by --pid if that option is present") do |v|
            options[:pidpath] = v
          end

          opts.on("--debug", "Turn on debug log level") do |v|
            options[:debug] = true
          end

          opts.on("--relentless", "Be relentless, fail fast, fail hard, do not continue processing when encountering component errors") do |v|
            options[:relentless] = true
          end

          opts.separator ""

          opts.separator "Common options:"

          # No argument, shows at tail.  This will print an options summary.
          # Try it and see!
          opts.on_tail("-h", "--help", "Show this message. Usage: #{script_name} -h") do
            puts opts
            exit
          end
        end
      end
    end
  end
end
