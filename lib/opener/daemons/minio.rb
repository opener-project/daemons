module Aws
  module Plugins
    class Minio < Seahorse::Client::Plugin

      def add_options config
        return unless endpoint = ENV['MINIO_ENDPOINT']
        config.add_option :endpoint, endpoint
        config.add_option :access_key_id,     ENV['MINIO_ACCESS_KEY']
        config.add_option :secret_access_key, ENV['MINIO_SECRET_KEY']
        config.add_option :force_path_style,  true
      end

    end
  end
end

Aws::S3::Client.add_plugin Aws::Plugins::Minio

