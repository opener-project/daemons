require 'spec_helper'

describe Opener::Daemons::Daemon do
  before do
    Opener::Daemons.stub(:input_queue).and_return('foo')
    Opener::Daemons.stub(:threads).and_return(0)

    @daemon = described_class.new(double(:component))

    @daemon.stub(:run_thread).and_return(true)
  end

  after do
    Thread.current[Opener::Daemons::Transaction::THREAD_KEY] = nil
  end

  context '#complete' do
    before do
      @message = double(:message, :id => 123)
      @timings = double(:timings)
    end

    example 'log data to Syslog upon completion' do
      Opener::Core::Syslog.should_receive(:info)
        .with('Finished message 123')

      @daemon.complete(@message, 'Done', @timings)
    end

    example 'reset the current transaction' do
      Opener::Daemons::Transaction.should_receive(:reset_current)

      @daemon.complete(@message, 'Done', @timings)
    end
  end

  context '#report_exception' do
    before do
      @error = StandardError.new('foo')
    end

    example 'report errors using Rollbar' do
      Opener::Daemons.stub(:rollbar?).and_return(true)

      Rollbar.should_receive(:error)
        .with(@error, an_instance_of(Hash))

      @daemon.report_exception(@error)
    end

    example 'reset the current transaction' do
      Opener::Daemons::Transaction.should_receive(:reset_current)

      -> { @daemon.report_exception(@error) }.should raise_error(StandardError)
    end
  end
end
