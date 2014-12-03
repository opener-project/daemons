module Opener
  module Daemons
    ##
    # Class for storing information of a single transaction in a thread.
    #
    # @!attribute [r] parameters
    #  @return [Hash]
    #
    class Transaction
      attr_reader :parameters

      ##
      # Returns the current transaction.
      #
      # @return [Opener::Daemons::Transaction]
      #
      def self.current
        return Thread.current[:opener_daemons_transaction] ||= new
      end

      ##
      # Removes the current transaction
      #
      def self.reset_current
        Thread.current[:opener_daemons_transaction] = nil
      end

      def initialize
        @parameters = {}
      end

      ##
      # Merges the given parameters with the existing ones.
      #
      # If New Relic is enabled the parameters are also added to the current
      # New Relic transaction.
      #
      # @param [Hash] parameters
      #
      def add_parameters(parameters = {})
        @parameters = @parameters.merge(parameters)

        if Daemons.newrelic?
          NewRelic::Agent.add_custom_parameters(parameters)
        end
      end
    end # Transaction
  end # Daemons
end # Opener
