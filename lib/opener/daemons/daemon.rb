require 'thread'
require 'opener/daemons/sqs'

module Opener
  module Daemons
    class Daemon
      attr_reader :batch_size,
                  :input_queue, :output_queue,
                  :input_buffer, :output_buffer,
                  :klass,
                  :logger

      attr_accessor :threads, :thread_counts

      def initialize(klass, options={})
        @input_queue  = Opener::Daemons::SQS.find(options.fetch(:input_queue))
        @output_queue = Opener::Daemons::SQS.find(options.fetch(:output_queue))

        @threads = {}
        @threads[:readers] = []
        @threads[:workers] = []
        @threads[:writers] = []

        @thread_counts = {}
        @thread_counts[:readers] = options.fetch(:readers, 1)
        @thread_counts[:workers] = options.fetch(:workers, 5)
        @thread_counts[:writers] = options.fetch(:writers, 1)

        @batch_size = options.fetch(:batch_size, 10)

        @input_buffer  = Queue.new
        @output_buffer = Queue.new

        @klass = klass

        script_name = File.basename($0, ".rb")
        @logger = Logger.new(options.fetch(:log, STDOUT))
        @logger.level = if options.fetch(:debug, false)
                          Logger::DEBUG
                        else
                          Logger::INFO
                        end

      end

      def buffer_new_messages
        if input_buffer.size > buffer_size
          #logger.debug "Maximum input buffer size reached"
          return
        end

        if output_buffer.size > buffer_size
          #logger.debug "Maximum output buffer size reached"
          return
        end

        messages = input_queue.receive_messages(batch_size)

        return if messages.nil?
        messages.each do |message|
          input_buffer << message
        end
      end

      def start
        Thread.abort_on_exception = true
        #
        # Load Readers
        #
        thread_counts[:readers].times do |t|
          threads[:readers] << Thread.new do
            logger.info "Producer #{t+1} ready for action..."
            loop do
              buffer_new_messages
            end
          end
        end

        #
        # Load Workers
        #
        thread_counts[:workers].times do |t|
          threads[:workers] << Thread.new do
            logger.info "Worker #{t+1} launching..."
            identifier = klass.new
            loop do
              message = input_buffer.pop

              input = JSON.parse(message[:body])["input"]
              begin
                output = identifier.run(input)
              rescue Exception => e
                logger.error(e)
                output = input
              end
              output_buffer.push({ :output=>output,
                                 :handle=>message[:receipt_handle]})
            end
          end
        end

        #
        # Load Writers
        #
        thread_counts[:writers].times do |t|
          threads[:writers] << Thread.new do
            logger.info "Pusher #{t+1} ready for action..."
            loop do
              message = output_buffer.pop

              payload = {:input=>message[:output]}.to_json
              output_queue.send_message(payload)
              input_queue.delete_message(message[:handle])
            end
          end
        end

        reporter = Thread.new do
          loop do
            logger.debug "input buffer: #{input_buffer.size} \t output buffer: #{output_buffer.size}"

            thread_types = [:readers, :workers, :writers]
            thread_counts = thread_types.map do |type|
              threads[type].select{|thread| thread.status}.count
            end
            zip = thread_types.zip(thread_counts)
            logger.debug "active thread counts: #{zip}"

            sleep(2)
          end
        end

        threads[:readers].each(&:join)
        threads[:workers].each(&:join)
        threads[:writers].each(&:join)
      end

      def buffer_size
        4 * batch_size
      end

    end
  end
end
