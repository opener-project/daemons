# encoding: UTF-8

require 'thread'
require 'opener/daemons/sqs'
require 'json'

Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

module Opener
  module Daemons
    class Daemon
      attr_reader :batch_size, :buffer_size, :sleep_interval,
                  :input_queue, :output_queue,
                  :input_buffer, :output_buffer,
                  :bucket_name, :bucket_dir, :file_suffix,
                  :klass,
                  :logger,
                  :script_name

      attr_accessor :threads, :thread_counts

      def initialize(klass, options={})

        @threads = {:readers=>[], :workers=>[], :writers=>[], :reporters=>[]}
        @thread_counts = {:readers => options.fetch(:readers, 1),
                          :workers => options.fetch(:workers, 5),
                          :writers => options.fetch(:writers, 1)}

        @relentless = options.fetch(:relentless, false)
        @sleep_interval = options.fetch(:sleep_interval, 5)

        # Initialize queues
        @input_queue  = Opener::Daemons::SQS.find(options.fetch(:input_queue))
        if options[:output_queue]
          @output_queue = Opener::Daemons::SQS.find(options[:output_queue])
        end
        
        # Get bucket name and other bucket options, if any.
        if @bucket_name = options[:bucket_name]
           @bucket_dir  = options.fetch(:bucket_dir, nil)
           @file_suffix = options.fetch(:file_suffix, nil)
         end

        # Initialize Buffers
        @input_buffer  = Queue.new
        @output_buffer = Queue.new

        # Batch and Buffer size for a smooth flow.
        @batch_size = options.fetch(:batch_size, 10)
        @buffer_size = options[:buffer_size]

        # Working component
        @klass = klass

        @script_name = File.basename($0, ".rb")

        @logger = Logger.new(options.fetch(:log, STDOUT))
        @logger.level = if options.fetch(:debug, false)
                          Logger::DEBUG
                        else
                          Logger::INFO
                        end

        logger.debug(options.to_json)
      end

      def buffer_new_messages
        return if input_buffer.size > buffer_size
        return if output_buffer.size > buffer_size
        messages = input_queue.receive_messages(batch_size)

        if messages.nil?
          sleep(sleep_interval)
          return
        end
        messages.each do |message|
          input_buffer << message
        end
      end

      def start
        Thread.abort_on_exception = true

        start_readers
        start_workers
        start_writers
        start_reporters

        threads[:readers].each(&:join)
        threads[:workers].each(&:join)
        threads[:writers].each(&:join)
        threads[:reporters].each(&:join)
      end

      def start_readers
        thread_counts[:readers].times do |t|
          threads[:readers] << Thread.new do
            logger.info "Reader #{t+1} ready for action..."
            loop do
              buffer_new_messages
            end
          end
        end
      end

      def start_workers
        thread_counts[:workers].times do |t|
          threads[:workers] << Thread.new do
            logger.info "Worker #{t+1} launching..."
            identifier = klass.new
            loop do
              message = input_buffer.pop
              
              input = get_input(message[:body])
              input,* = input if input.kind_of?(Array)

              begin
                output, * = identifier.run(input)
                if output.empty?
                  raise "The component returned an empty response."
                end
              rescue Exception => e
                if relentless?
                  raise
                else
                  logger.error(e)
                  output = input
                end
              end
              message[:body].delete("input")
              output_buffer.push({ :output=>output, 
                                   :body => message[:body],
                                   :handle=>message[:receipt_handle]
                                   })
            end
          end
        end
      end

      def start_writers
        thread_counts[:writers].times do |t|
          threads[:writers] << Thread.new do
            logger.info "Pusher #{t+1} ready for action..."
            loop do
              message = output_buffer.pop
              callbacks = extract_callbacks(message[:body]["callbacks[]"])
              handler = Opener::CallbackHandler.new
              
              if bucket_name
                filename = [message[:body]["request_id"], script_name, Time.now.to_i].join("-")
                s3 = Opener::Daemons::S3.new(bucket_name, message[:output].force_encoding("UTF-8"), filename,  bucket_dir, file_suffix)
                s3.upload
                message[:body][:input_url] = s3.url
              else
                message[:body][:input] = message[:output].force_encoding("UTF-8")
              end
              
              
              unless callbacks.empty?
                callback_url = callbacks.shift
                message[:body][:'callbacks[]'] = callbacks
                payload = {:body => message[:body]}
                handler.post(callback_url, payload)
              else
                payload = {:body => message[:body]}
                handler.post(output_queue.queue_url, payload)
              end
              input_queue.delete_message(message[:handle])
              
            end
          end
        end
      end

      def start_reporters
        threads[:reporters] << Thread.new do
          loop do
            log = {:buffers=>{:input=>input_buffer.size}}
            log[:buffers][:output] = output_buffer.size if output_buffer

            logger.debug log.to_json
            sleep(2)
          end
        end

        threads[:reporters] << Thread.new do
          loop do
            thread_types = threads.keys - [:reporters]
            thread_counts = thread_types.map do |type|
              threads[type].select{|thread| thread.status}.count
            end
            zip = thread_types.zip(thread_counts)
            logger.debug "active thread counts: #{zip}"

            sleep(10)
          end
        end
      end

      def buffer_size
        @buffer_size ||= (4 * batch_size)
      end

      def relentless?
        @relentless
      end
      
      ##
      # Returns an Array containing the callback URLs, ignoring empty values.
      #
      # @param [Array|String] input
      # @return [Array]
      #
      def extract_callbacks(input)
        return [] if input.nil? || input.empty?

        callbacks = input.compact.reject(&:empty?)

        return callbacks
      end
      
      def get_input(body)
        return body.delete("input") if body["input"]
        return HTTPClient.new.get(body.delete("input_url")).body if body["input_url"]
      end
    end
  end
end
