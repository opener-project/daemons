require 'spec_helper'

describe Opener::Daemons::Uploader do
  before do
    @uploader = described_class.new
  end

  context '#upload' do
    example 'upload a document to S3' do
      SecureRandom.should_receive(:hex)
        .and_return('123')

      @uploader.should_receive(:create).with(
        '123/foo.xml',
        'Hello',
        :metadata     => {:a => 10},
        :content_type => 'application/xml',
        :acl          => 'public-read'
      )

      @uploader.upload('foo', 'Hello', :a => 10)
    end
  end

  context '#create' do
    example 'upload an object to S3' do
      Opener::Daemons.stub(:output_bucket => 'foo')

      bucket = Aws::S3::Bucket.new('foo')

      @uploader.s3
        .should_receive(:bucket)
        .with('foo')
        .and_return(bucket)

      bucket.should_receive(:put_object)
        .with(:key => 'foo', :body => 'bar', :content_type => 'text/plain')

      @uploader.create('foo', 'bar', :content_type => 'text/plain')
    end
  end
end
