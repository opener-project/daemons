require 'spec_helper'

describe Opener::Daemons::Daemon do
  before do
    Opener::Daemons.stub(:input_queue).and_return('foo')
    Opener::Daemons.stub(:threads).and_return(0)

    @daemon = described_class.new(double(:component))

    @daemon.stub(:run_thread).and_return(true)
  end

  context 'unwrapping errors' do
    before do
      @original = StandardError.new('foo')
      @params   = {:foo => :bar}
    end

    example 'unwrap a regular error' do
      error, params = @daemon.unwrap_error(@original)

      error.should  == @original
      params.should == {}
    end

    example 'unwrap a wrapped error' do
      input = Oni::WrappedError.from(@original, @params)

      error, params = @daemon.unwrap_error(input)

      error.should  == @original
      params.should == @params
    end
  end
end
