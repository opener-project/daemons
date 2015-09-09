module Opener
  module Daemons
    # Class for uploading KAF documents to Amazon S3.
    class Uploader
      # Uploads the given KAF document.
      #
      # @param [String] identifier
      # @param [String] document
      # @param [Hash] metadata description
      #
      # @return [Aws::S3::Object]
      def upload(identifier, document, metadata = {})
        converted_metadata = {}

        metadata.each do |key, value|
          converted_metadata[key.to_s] = value.to_s
        end

        object = create(
          "#{SecureRandom.hex}/#{identifier}.xml",
          document,
          :metadata     => converted_metadata,
          :content_type => 'application/xml',
          :acl          => 'public-read'
        )

        return object
      end

      # @param [String] key
      # @param [String] body
      # @param [Hash] options
      # @return [Aws::S3::Object]
      def create(key, body, options = {})
        bucket.put_object(options.merge(:key  => key, :body => body))
      end

      # @return [Aws::S3::Resource]
      def s3
        @s3 ||= Aws::S3::Resource.new
      end

      # @return [Aws::S3::Bucket]
      def bucket
        @bucket ||= s3.bucket(Daemons.output_bucket)
      end
    end # Uploader
  end # Daemons
end # Opener
