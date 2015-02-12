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
      end

      ##
      # Processes a document.
      #
      # @raise [Oni::WrappedError]
      #
      def process
        add_transaction_attributes

        begin
          output = run_component
          object = upload_output(output)

          submit_callbacks(object)

        # Unsupported languages are handled in a different manner as they can
        # occur quite often. In these cases we _do_ want the data to be sent
        # to the final callback URL (skipping whatever comes before it) so it
        # can act upon it.
        rescue Core::UnsupportedLanguageError
          handle_unsupported_language
        end
      end

      ##
      # @return [String]
      #
      def run_component
        input = downloader.download(config.input_url)

        return config.component_instance.run(input)
      end

      ##
      # @param [String] output
      # @return [AWS::S3::S3Object]
      #
      def upload_output(output)
        object = uploader.upload(config.identifier, output, config.metadata)

        Core::Syslog.info(
          "Wrote output to s3://#{Daemons.output_bucket}/#{object.key}",
          config.metadata
        )

        return object
      end

      ##
      # Sends the object's URL to the next callback URL.
      #
      # @param [AWS::S3::S3Object] object
      #
      def submit_callbacks(object)
        urls      = config.callbacks.dup
        next_url  = urls.shift
        input_url = object.url_for(:read, :expires => 86400)

        callback_handler.post(
          next_url,
          :input_url  => input_url,
          :identifier => config.identifier,
          :callbacks  => urls,
          :metadata   => config.metadata
        )

        Core::Syslog.info("Submitted response to #{next_url}", config.metadata)
      end

      ##
      # Sends the unsupported input to the last callback URL.
      #
      def handle_unsupported_language
        last_url = config.callbacks.last

        callback_handler.post(
          last_url,
          :input_url  => config.input_url,
          :identifier => config.identifier,
          :metadata   => config.metadata
        )

        Core::Syslog.info(
          "Submitted input with an unsupported language to #{last_url}",
          config.metadata
        )
      end

      private

      def add_transaction_attributes
        Transaction.current.add_parameters(
          :input_url  => config.input_url,
          :identifier => config.identifier,
          :callbacks  => config.callbacks,
          :metadata   => config.metadata
        )
      end

      if Daemons.newrelic?
        add_transaction_tracer(:process, :category => :task)
        add_method_tracer(:download_input)
      end
    end # Worker
  end # Daemons
end # Opener
