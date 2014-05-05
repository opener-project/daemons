require 'optparse'

module Opener
  module Daemons
    class OptParser

      def self.parse(args)
        process(args, :parse)
      end

      def self.parse!(args)
        process(args, :parse!)
      end

      def self.process(args, call)
        options = {}

        OptionParser.new do |opts|
          opts.banner = "Usage: language-identifier.rb <start|stop|restart> [options]"
          opts.separator ""
          opts.separator "Specific options:"

          opts.on("-i", "--input INPUT_QUEUE_NAME", "Input queue name") do |v|
            options[:input_queue] = v
          end

          opts.on("-o", "--output OUTPUT_QUEUE_NAME", "Output queue name") do |v|
            options[:output_queue] = v
          end

          opts.on("-b", "--batch-size BATCH_SIZE", Integer, "Request x messages at once where x is between 1 and 10") do |v|
            options[:batch_size] = v
          end

          opts.on("-w", "--workers NUMBER", Integer, "number of worker thread") do |v|
            options[:workers] = v
          end

          opts.on("-r", "--readers NUMBER", Integer, "number of reader threads") do |v|
            options[:readers] = v
          end

          opts.on("-p", "--writers NUMBER", Integer, "number of writer / pusher threads") do |v|
            options[:writers] = v
          end

          opts.on("--log FILENAME", "Filename and path of logfile. Defaults to STDOUT") do |v|
            options[:log] = v
          end

          opts.on("--pid FILENAME", "Filename and path of pidfile. Defaults to /var/run/{basename of current script}.pid") do |v|
            options[:pid] = v
          end

          opts.on("--pidpath DIRNAME", "Directory where to put the PID file. Is Overwritten by --pid if that option is present") do |v|
            options[:pidpath] = v
          end

          opts.on("--debug", "Turn on debug log level") do |v|
            options[:debug] = true
          end

          opts.separator ""

          opts.separator "Common options:"

          # No argument, shows at tail.  This will print an options summary.
          # Try it and see!
          opts.on_tail("-h", "--help", "Show this message") do
            puts opts
            exit
          end
        end.send(call, args)

        return options
      end
    end
  end
end
