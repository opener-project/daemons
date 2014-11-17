require 'spec_helper'

describe Opener::Daemons::Configuration do
  context '#initialize' do
    before do
      @component = double(:component)
    end

    example 'set the component' do
      described_class.new(@component).component.should == @component
    end

    example 'set the component options' do
      config = described_class.new(@component, :number => 10)

      config.component_options.should == {:number => 10}
    end

    example 'set the input URL' do
      config = described_class.new(@component, {}, :input_url => 'foo')

      config.input_url.should == 'foo'
    end

    example 'set the list of callback URLs' do
      config = described_class.new(@component, {}, :callbacks => %w{foo})

      config.callbacks.should == %w{foo}
    end

    example 'set the metadata Hash' do
      config = described_class.new(@component, {}, :metadata => {:a => 1})

      config.metadata.should == {:a => 1}
    end

    example 'set the default callback URLs' do
      described_class.new(@component).callbacks.should == []
    end

    example 'set the default metadata Hash' do
      described_class.new(@component).metadata.should == {}
    end
  end

  context '#identifier' do
    example 'return a custom set identifier' do
      config = described_class.new(@component, {}, :identifier => 'foo')

      config.identifier.should == 'foo'
    end

    example 'return a randomly generated identifier if no custom one is given' do
      config = described_class.new(@component)

      config.identifier.empty?.should == false
    end
  end
end
