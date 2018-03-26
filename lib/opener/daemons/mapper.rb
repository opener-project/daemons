module Opener
  module Daemons
    ##
    # Maps the input/output between the daemon and the worker in such a format
    # that both ends can work with it easily.
    #
    # @!attribute [r] component
    #  @return [Class]
    #
    # @!attribute [r] component_options
    #  @return [Hash]
    #
    class Mapper < Oni::Mapper
      attr_reader :component, :component_options

      ##
      # The directory containing JSON schema files.
      #
      # @return [String]
      #
      SCHEMA_DIRECTORY = File.expand_path('../../../../schema', __FILE__)

      ##
      # Path to the schema file.
      #
      # @return [String]
      #
      INPUT_SCHEMA_FILE = if Worker::INLINE_IO then 'inline_sqs_input.json' else 'sqs_input.json' end
      INPUT_SCHEMA = File.join SCHEMA_DIRECTORY, INPUT_SCHEMA_FILE

      ##
      # @param [Class] component
      # @param [Hash] component_options
      #
      def initialize(component, component_options = {})
        @component         = component
        @component_options = component_options
      end

      ##
      # @param [AWS::SQS::ReceivedMessage] message
      # @return [Hash]
      #
      def map_input(message)
        decoded = JSON(message.body)

        validate_input!(decoded)

        return Configuration.new(component, component_options, decoded)
      end

      ##
      # Validates the given input Hash.
      #
      # @param [Hash] input
      # @raise [JSON::Schema::ValidationError]
      #
      def validate_input!(input)
        JSON::Validator.validate!(INPUT_SCHEMA, input)
      end
    end # Mapper
  end # Daemons
end # Opener
