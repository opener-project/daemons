module Opener
  module Daemons
    ##
    # Downloads and validates text/XML documents used as input.
    #
    # @!attribute [r] http
    #  @return [HTTPClient]
    #
    class Downloader
      attr_reader :http

      def initialize
        @http = HTTPClient.new
      end

      ##
      # Downloads the document located at `url`.
      #
      # @param [String] url
      # @return [String]
      #
      def download(url)
        resp = http.get(url, :follow_redirect => true)

        unless resp.ok?
          raise(
            HTTPClient::BadResponseError,
            "Got HTTP #{resp.status}: #{resp.body}"
          )
        end

        return resp.body
      end
    end # Downloader
  end # Daemons
end # Opener
