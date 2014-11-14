require 'spec_helper'

describe Opener::Daemons::Mapper do
  before do
    @mapper = described_class.new(double(:component))
  end

  context '#initialize' do
    example 'set the component' do
      described_class.new(String).component.should == String
    end
  end

  context '#map_input' do
    before do
      body = JSON.dump(
        :input_url => 'http://example.com',
        :callbacks => %w{http://foo.com},
        :metadata  => {:number => 10}
      )

      @message = double(:message, :body => body)
    end

    example 'validate the message' do
      @mapper.should_receive(:validate_input!).with(an_instance_of(Hash))

      @mapper.map_input(@message)
    end

    example 'return a Configuration object' do
      @mapper.map_input(@message)
        .is_a?(Opener::Daemons::Configuration)
        .should == true
    end

    example 'set the input URL of the Configuration object' do
      @mapper.map_input(@message).input_url.should == 'http://example.com'
    end

    example 'set the callback URLs of the Configuration object' do
      @mapper.map_input(@message).callbacks.should == %w{http://foo.com}
    end

    example 'set the metadata of the Configuration object' do
      @mapper.map_input(@message).metadata.should == {'number' => 10}
    end
  end

  context '#validate_input!' do
    example 'raise if all required fields are missing' do
      block = -> { @mapper.validate_input!({}) }

      block.should raise_error(JSON::Schema::ValidationError)
    end

    example 'raise if the "callbacks" field is not specified' do
      block = -> { @mapper.validate_input!('input_url' => 'foo') }

      block.should raise_error(JSON::Schema::ValidationError)
    end

    example 'raise if the "callbacks" field is not an array' do
      block = -> do
        @mapper.validate_input!(
          'input_url' => 'http://foo.com',
          'callbacks' => 'bar'
        )
      end

      block.should raise_error(JSON::Schema::ValidationError)
    end

    example 'raise if the "metadata" field is not an object' do
      block = -> do
        @mapper.validate_input!(
          'input_url' => 'http://foo.com',
          'metadata'  => 'foo'
        )
      end

      block.should raise_error(JSON::Schema::ValidationError)
    end

    example 'do not raise raise when all required fields are specified' do
      block = -> do
        @mapper.validate_input!(
          'input_url' => 'http://foo.com',
          'callbacks' => %w{foo}
        )
      end

      block.should_not raise_error
    end
  end
end
