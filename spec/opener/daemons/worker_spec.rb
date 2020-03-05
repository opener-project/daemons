require 'spec_helper'

describe Opener::Daemons::Worker do

  INPUT  = 'Hello'
  OUTPUT = 'World'

  let :component do
    Class.new do
      def initialize *; end

      def run input, options = {}
        OUTPUT
      end
    end
  end

  describe 'with inline IO' do
    before :all do
      described_class::INLINE_IO = true
    end

    before do
      @config_input = Base64.encode64(Zlib.gzip(INPUT))
      @config = Opener::Daemons::Configuration.new(
        component,
        {},
        input:     @config_input,
        callbacks: %w{http://foo.com},
        metadata:  {'a' => 1, 'custom_config' => {'abc' => 'def'}},
      )
      @worker = described_class.new @config
    end

    let :next_input do
      Base64.encode64 Zlib.gzip OUTPUT
    end

    context '#process' do
      example 'process the input using the component' do
        @worker.stub(:submit_callbacks)

        @worker.process

        expect(@worker.instance_variable_get :@output).to eq OUTPUT
        expect(@worker.instance_variable_get :@next_input).to eq next_input
      end

      example 'submit the output to the next callback' do
        @worker.should_receive(:submit_callbacks)

        @worker.process
        expect(@worker.instance_variable_get :@object).to eq @s3_object
      end

      example 'submit custom_config to component' do
        expect_any_instance_of(component).to receive(:run)
          .with(INPUT, @config.metadata['custom_config'])
          .and_call_original

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
          input:      next_input,
          identifier: @config.identifier,
          callbacks:  [],
          metadata:   @config.metadata,
        }

        @worker.callback_handler.should_receive(:post)
          .with('http://foo.com', hash)

        @worker.process
      end
    end

    context '#handle_unsupported_language' do
      example 'send the input URL to the last callback URL' do
        hash = {
          input:      @config.input,
          identifier: @config.identifier,
          metadata:   @config.metadata,
        }

        @worker.callback_handler.should_receive(:post)
          .with('http://foo.com', hash)
        @worker.stub(:run_component)
          .and_raise(Opener::Core::UnsupportedLanguageError, 'bacon')

        @worker.process
      end
    end
  end

  describe 'without inline IO' do

    before :all do
      described_class::INLINE_IO = false
    end

    before do
      @config = Opener::Daemons::Configuration.new(
        component,
        {},
        input_url: 'http://example.com',
        callbacks: %w{http://foo.com},
        metadata:  {:a => 1},
      )
      @worker = described_class.new @config

      @worker.downloader.stub(:download).and_return INPUT

      @s3_object = Aws::S3::Object.new('foo', 'bar')
      @s3_object.stub(:public_url).and_return('http://s3-example')
      @worker.uploader.stub(:upload).and_return(@s3_object)
    end

    context '#process' do
      example 'process the input using the component' do
        component.any_instance.should_receive(:run).with INPUT, nil

        @worker.stub(:submit_callbacks)

        @worker.process
      end

      example 'upload the output to S3' do
        @worker.uploader.should_receive(:upload)
          .with(@config.identifier, OUTPUT, @config.metadata)

        @worker.stub(:submit_callbacks)

        @worker.process
      end

      example 'submit the output to the next callback' do
        @worker.should_receive(:submit_callbacks)

        @worker.process
        expect(@worker.instance_variable_get :@object).to eq @s3_object
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
          input_url:  'http://s3-example',
          identifier: @config.identifier,
          callbacks:  [],
          metadata:   @config.metadata,
        }

        @worker.callback_handler.should_receive(:post)
          .with('http://foo.com', hash)

        @worker.process_output
        @worker.submit_callbacks
      end
    end

    context '#handle_unsupported_language' do
      example 'send the input URL to the last callback URL' do
        hash = {
          input_url:  @config.input_url,
          identifier: @config.identifier,
          metadata:   @config.metadata,
        }

        @worker.callback_handler.should_receive(:post)
          .with('http://foo.com', hash)

        @worker.process_output
        @worker.handle_unsupported_language
      end
    end
  end

end
