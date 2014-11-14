require 'spec_helper'

describe Opener::Daemons::Pidfile do
  before do
    @pid = described_class.new(Dir::Tmpname.make_tmpname('rspec', Process.pid))
  end

  after do
    @pid.unlink
  end

  context '#read / #write' do
    example 'write and read a PID' do
      @pid.write(123)

      @pid.read.should == 123
    end
  end

  context '#unlink' do
    example 'remove a PID file' do
      @pid.unlink

      File.file?(@pid.path).should == false
    end
  end

  context '#terminate' do
    before do
      @id = 123

      @pid.write(@id)
    end

    # Bit of an odd test but it's better than nothing.
    example 'terminate the process' do
      Process.should_receive(:kill).with('TERM', @id)
      Process.should_receive(:wait).with(@id)

      -> { @pid.terminate }.should_not raise_error
    end

    example 'return gracefully when Process.kill raises ESRCH' do
      Process.stub(:kill).and_raise(Errno::ESRCH)

      -> { @pid.terminate }.should_not raise_error
    end

    example 'return gracefully when Process.kill raises ECHILD' do
      Process.stub(:kill).and_raise(Errno::ECHILD)

      -> { @pid.terminate }.should_not raise_error
    end

    example 're-raise errors other than ESRCH and ECHILD' do
      Process.stub(:kill).and_raise(Errno::EPERM)

      -> { @pid.terminate }.should raise_error(Errno::EPERM)
    end
  end

  context '#alive?' do
    before do
      @pid.write(Process.pid)
    end

    example 'return true if the process is alive' do
      @pid.alive?.should == true
    end

    example 'return false if the process does not exist' do
      Process.stub(:kill).and_raise(Errno::ESRCH)

      @pid.alive?.should == false
    end

    example 'return false if the access to the process was denied' do
      Process.stub(:kill).and_raise(Errno::EPERM)

      @pid.alive?.should == false
    end
  end
end
