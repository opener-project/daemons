require 'spec_helper'

describe Opener::Daemons::Downloader do
  before do
    @downloader = described_class.new
  end

  context '#download' do
    example 'download a document' do
      response = HTTP::Message.new_response('Hello')

      @downloader.http.stub(:get).and_return(response)

      @downloader.download('http://example.com').should == 'Hello'
    end

    example 'raise HTTPClient::BadResponseError for missing documents' do
      response        = HTTP::Message.new_response('nope')
      response.status = 404

      @downloader.http.stub(:get).and_return(response)

      block = -> { @downloader.download('http://example.com') }

      block.should raise_error(
        HTTPClient::BadResponseError,
        'Got HTTP 404: nope'
      )
    end
  end
end
