require 'aws-sdk-core'

module Opener
  module Daemons
    class SQS
      attr_reader :sqs, :name, :url

      def self.find(name)
        new(name)
      end

      def initialize(name)
        @sqs = Aws::SQS.new
        @name = name
        begin
          @url = sqs.get_queue_url(:queue_name=>name)[:queue_url]
        rescue Aws::SQS::Errors::NonExistentQueue => e
          STDERR.puts "Could not find queue #{name}"
          raise
        end
      end

      def send_message(message)
        sqs.send_message(:queue_url=>url, :message_body=>message)
      end

      def delete_message(handle)
        sqs.delete_message(:queue_url=>url, :receipt_handle=>handle)
      end

      def receive_messages(limit)
        result = sqs.receive_message(:queue_url=>url,
                                     :max_number_of_messages=>limit)[:messages]
      end

    end
  end
end
