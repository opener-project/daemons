require 'aws-sdk'

module Opener
  module Daemons
    class S3
      attr_reader :s3_client, :bucket_name, :content, :filename, :directory, :url

      def initialize(bucket_name, content, filename, directory = nil, filename_suffix = nil)
        @s3_client   = AWS::S3.new
        @bucket_name = bucket_name
        @filename    = [filename, filename_suffix].compact.reject{|e| e.empty?}.join("-")
        @content     = content
        @directory   = directory
      end
      
      def upload
        @filename = File.join(directory, filename) if directory
        bucket = s3_client.buckets[bucket_name]
        object = bucket.objects["#{filename}.kaf"]

        object.write(content)
        
        @url = object.url_for(
          :read,
          :secure                       => false,
          :force_path_style             => false,
          :response_content_type        => "application/xml",
          :response_content_disposition => "attachment",
          :expires                      => 7 * 24 * 60 * 60 # 7 days
        )
      end
    end
  end
end
