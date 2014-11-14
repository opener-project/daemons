module Opener
  module Daemons
    ##
    # Maps the input/output between the daemon and the worker in such a format
    # that both ends can work with it easily.
    #
    # @!attribute [r] component
    #  @return [Class]
    #
    class Mapper < Oni::Mapper
      attr_reader :component

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
      INPUT_SCHEMA = File.join(SCHEMA_DIRECTORY, 'sqs_input.json')

      ##
      # @param [Class] component
      #
      def initialize(component)
        @component = component
      end

      ##
      # @param [AWS::SQS::ReceivedMessage] message
      # @return [Hash]
      #
      def map_input(message)
        decoded = JSON(message.body)

        validate_input!(decoded)

        return Configuration.new(component, decoded)
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
