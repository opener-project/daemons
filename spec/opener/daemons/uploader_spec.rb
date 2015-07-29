require 'spec_helper'

describe Opener::Daemons::Uploader do
  before do
    @uploader = described_class.new
  end

  context '#upload' do
    example 'upload a document to S3' do
      @uploader.should_receive(:create).with(
        %r{[a-zA-Z0-9]+/foo\.xml},
        'Hello',
        :metadata     => {:a => 10},
        :content_type => 'application/xml',
        :acl          => :public_read
      )

      @uploader.upload('foo', 'Hello', :a => 10)
    end
  end

  context '#create' do
    example 'return an S3Object' do
      object = AWS::S3::S3Object.new('foo', 'bar')

      AWS::S3::ObjectCollection.any_instance
        .should_receive(:create)
        .and_return(object)

      @uploader.create('foo.xml').should == object
    end

    example 'return an S3Object when versioning is enabled' do
      object  = AWS::S3::S3Object.new('foo', 'bar')
      version = AWS::S3::ObjectVersion.new(object, '123')

      AWS::S3::ObjectCollection.any_instance
        .should_receive(:create)
        .and_return(version)

      @uploader.create('foo.xml').should == object
    end
  end
end
