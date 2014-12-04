require 'spec_helper'

describe Opener::Daemons::Worker do
  before do
    @component = Class.new do
      def initialize(*); end

      def run(*)
        return 'Output'
      end
    end

    @config = Opener::Daemons::Configuration.new(
      @component,
      {},
      :input_url => 'http://example.com',
      :callbacks => %w{http://foo.com},
      :metadata  => {:a => 1}
    )

    @worker    = described_class.new(@config)
    @input     = 'Hello'
    @s3_object = AWS::S3::S3Object.new('foo', 'bar')

    @s3_object.stub(:url_for).and_return('http://s3-example')

    @worker.downloader.stub(:download).and_return(@input)
    @worker.uploader.stub(:upload).and_return(@s3_object)
  end

  context '#process' do
    example 'process the input using the component' do
      @component.any_instance.should_receive(:run).with(@input)

      @worker.stub(:submit_callbacks)

      @worker.process
    end

    example 'upload the output to S3' do
      @worker.uploader.should_receive(:upload)
        .with(@config.identifier, 'Output', @config.metadata)

      @worker.stub(:submit_callbacks)

      @worker.process
    end

    example 'submit the output to the next callback' do
      @worker.should_receive(:submit_callbacks)
        .with(@s3_object)

      @worker.process
    end

    example 'submit documents with unsupported languages to the last callback' do
      @worker.should_receive(:handle_unsupported_language)

      @worker.stub(:run_component)
        .and_raise(Opener::Core::UnsupportedLanguageError, 'bacon')

      @worker.process
    end
  end

  context '#submit_callbacks' do
    example 'send an object to the next callback URL' do
      hash = {
        :input_url  => 'http://s3-example',
        :identifier => @config.identifier,
        :callbacks  => [],
        :metadata   => @config.metadata
      }

      @worker.callback_handler.should_receive(:post)
        .with('http://foo.com', hash)

      @worker.submit_callbacks(@s3_object)
    end
  end

  context '#handle_unsupported_language' do
    example 'send the input URL to the last callback URL' do
      hash = {
        :input_url  => @config.input_url,
        :identifier => @config.identifier,
        :metadata   => @config.metadata
      }

      @worker.callback_handler.should_receive(:post)
        .with('http://foo.com', hash)

      @worker.handle_unsupported_language
    end
  end
end
