module Opener
  module Daemons
    ##
    # Downlods a KAF document, passes it to a component and submits the output
    # to a callback URL or a default queue. Each Worker instance runs in an
    # isolated thread
    #
    # @!attribute [r] config
    #  @return [Opener::Daemons::Configuration]
    #
    # @!attribute [r] uploader
    #  @return [Opener::Daemons::Uploader]
    #
    # @!attribute [r] downloader
    #  @return [Opener::Daemons::Downloader]
    #
    # @!attribute [r] callback_handler
    #  @return [Opener::CallbackHandler]
    #
    class Worker < Oni::Worker
      attr_reader :config, :uploader, :downloader, :callback_handler

      INLINE_IO = !!ENV['INLINE_IO']

      include NewRelic::Agent::Instrumentation::ControllerInstrumentation
      include NewRelic::Agent::MethodTracer

      ##
      # @param [Opener::Daemons::Configuration] config
      #
      def initialize(config)
        @config           = config
        @downloader       = Downloader.new
        @uploader         = Uploader.new
        @callback_handler = CallbackHandler.new
        @input            = nil
        @output           = nil
      end

      ##
      # Processes a document.
      #
      # @raise [Oni::WrappedError]
      #
      def process
        add_transaction_attributes

        begin
          process_input
          run_component
          process_output
          submit_callbacks

        # Unsupported languages are handled in a different manner as they can
        # occur quite often. In these cases we _do_ want the data to be sent
        # to the final callback URL (skipping whatever comes before it) so it
        # can act upon it.
        rescue Core::UnsupportedLanguageError
          handle_unsupported_language
        end
      end

      ##
      #
      def process_input
        if config.input
          @input = Zlib.gunzip Base64.decode64 config.input
          @input.force_encoding 'UTF-8'
        else
          @input = downloader.download config.input_url
        end
      end

      ##
      # @return [String]
      #
      def run_component
        @output = config.component_instance.run @input
      end

      ##
      # @param [String] output
      # @return [Aws::S3::Object]
      #
      def process_output
        if INLINE_IO
          @next_input = Base64.encode64 Zlib.gzip @output
        else
          @object = uploader.upload config.identifier, @output, config.metadata
        end
      end

      ##
      # Sends the object's URL to the next callback URL.
      #
      # @param [Aws::S3::Object] object
      #
      def submit_callbacks
        urls     = config.callbacks.dup
        next_url = urls.shift

        callback_handler.post next_url, next_input_params.merge(
          identifier: config.identifier,
          callbacks:  urls,
          metadata:   config.metadata,
        )

        Core::Syslog.info("Submitted response to #{next_url}", config.metadata)
      end

      ##
      # Sends the unsupported input to the last callback URL.
      #
      def handle_unsupported_language
        last_url = config.callbacks.last

        callback_handler.post last_url, input_params.merge(
          identifier: config.identifier,
          metadata:   config.metadata,
        )

        Core::Syslog.info(
          "Submitted input with an unsupported language to #{last_url}",
          config.metadata
        )
      end

      private

      ##
      # Preserve input for last callback
      #
      def input_params
        if config.input_url
          {input_url: config.input_url}
        else
          {input:     config.input}
        end
      end

      ##
      # Use generated output as new input
      #
      def next_input_params
        if INLINE_IO
          {input:     @next_input}
        else
          {input_url: @object.public_url.to_s}
        end
      end

      def add_transaction_attributes
        Transaction.current.add_parameters(
          input_url:  config.input_url,
          identifier: config.identifier,
          callbacks:  config.callbacks,
          metadata:   config.metadata,
        )
      end

      if Daemons.newrelic?
        add_transaction_tracer :process, category: :task

        add_method_tracer :run_component
        add_method_tracer :process_output
        add_method_tracer :submit_callbacks
      end
    end # Worker
  end # Daemons
end # Opener
