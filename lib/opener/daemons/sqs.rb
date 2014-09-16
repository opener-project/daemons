require 'aws-sdk-core'

module Opener
  module Daemons
    class SQS
      attr_reader :sqs, :name, :url

      def self.find(name)
        new(name)
      end

      def initialize(name)
        @sqs = Aws::SQS::Client.new
        @name = name
        begin
          @url = sqs.get_queue_url(:queue_name=>name)[:queue_url]
        rescue Aws::SQS::Errors::NonExistentQueue => e
          sqs.create_queue(:queue_name=>name)
          retry
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
                                     :max_number_of_messages=>limit)[:messages] rescue []
                                            
        result ? to_hash(result) : []                       
                                     
      end
      
      def to_hash(messages)
        messages.map do |m| 
          hash = m.to_hash
          json_body = JSON.parse(hash.delete(:body))
          hash[:body] = json_body["body"] ? json_body["body"] : json_body
          hash
        end
      end
      
      def queue_url
        url
      end

    end
  end
end
