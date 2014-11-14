module Opener
  module Daemons
    ##
    # Configuration object for storing details about a single job.
    #
    # @!attribute [r] component
    #  @return [Class]
    #
    # @!attribute [r] input_url
    #  @return [String]
    #
    # @!attribute [r] callbacks
    #  @return [Array]
    #
    # @!attribute [r] metadata
    #  @return [Hash]
    #
    class Configuration
      attr_reader :component, :input_url, :callbacks, :metadata

      ##
      # @param [Class] component
      # @param [Hash] options
      #
      # @option options [String] :input_url
      # @option options [String] :identifier
      # @option options [Array] :callbacks
      # @option options [Hash] :metadata
      #
      def initialize(component, options = {})
        @component = component

        options.each do |key, value|
          instance_variable_set("@#{key}", value) if respond_to?(key)
        end

        @callbacks ||= []
        @metadata  ||= {}
      end

      ##
      # Returns the identifier of the document. If no identifier was given a
      # unique one will be generated instead.
      #
      # @return [String]
      #
      def identifier
        return @identifier ||= SecureRandom.hex
      end
    end # Configuration
  end # Daemons
end # Opener
