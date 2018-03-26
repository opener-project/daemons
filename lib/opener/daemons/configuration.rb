module Opener
  module Daemons
    ##
    # Configuration object for storing details about a single job.
    #
    # @!attribute [r] component
    #  @return [Class]
    #
    # @!attribute [r] component_options
    #  @return [Hash]
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

      attr_reader :component, :component_options

      attr_reader :input, :input_url
      attr_reader :callbacks, :metadata

      ##
      # @param [Class] component The component to use.
      # @param [Hash] component_options Options to pass to the component.
      #
      # @param [Hash] options
      #
      # @option options [String] :input_url
      # @option options [String] :identifier
      # @option options [Array] :callbacks
      # @option options [Hash] :metadata
      #
      def initialize(component, component_options = {}, options = {})
        @component         = component
        @component_options = component_options

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

      ##
      # Returns a new instance of the component.
      #
      # @return [Object]
      #
      def component_instance
        return component.new(component_options)
      end

    end # Configuration
  end # Daemons
end # Opener
