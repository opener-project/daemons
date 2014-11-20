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
        add_newrelic_attributes

        input    = downloader.download(config.input_url)
        output   = config.component_instance.run(input)
        object   = uploader.upload(config.identifier, output, config.metadata)

        Core::Syslog.info(
          "Wrote output to s3://#{Daemons.output_bucket}/#{object.key}",
          config.metadata
        )

        submit_callbacks(object)

      rescue Exception => error
        raise Oni::WrappedError.from(
          error,
          :input_url => config.input_url,
          :callbacks => config.callbacks,
          :metadata  => config.metadata
        )
      end

      ##
      # Sends the object's URL to the next callback URL.
      #
      # @param [AWS::S3::S3Object] object
      #
      def submit_callbacks(object)
        urls      = config.callbacks.dup
        next_url  = urls.shift
        input_url = object.url_for(:read, :expires => 3600)

        callback_handler.post(
          next_url,
          :input_url  => input_url,
          :identifier => config.identifier,
          :callbacks  => urls,
          :metadata   => config.metadata
        )

        Core::Syslog.info("Submitted response to #{next_url}", config.metadata)
      end

      private

      def add_newrelic_attributes
        if Daemons.newrelic?
          NewRelic::Agent.add_custom_attributes(
            :input_url => config.input_url,
            :callbacks => config.callbacks.join(', '),
            :metadata  => config.metadata
          )
        end
      end

      if Daemons.newrelic?
        add_transaction_tracer(:process, :category => :task)
        add_method_tracer(:download_input)
      end
    end # Worker
  end # Daemons
end # Opener
