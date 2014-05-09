#
# Original Idea by Charles Nutter
# Copied from: https://gist.github.com/ik5/448884
# Then adjusted.
#

require 'rubygems'
require 'opener/daemons'
require 'spoon'

module Opener
  module Daemons
    class Controller
      attr_reader :name, :exec_path

      def initialize(options={})
        @exec_path = options.fetch(:exec_path)
        @name = determine_name(options[:name])
        read_commandline
      end

      def determine_name(name)
        return identify(name) unless name.nil?
        get_name_from_exec_path
      end

      def get_name_from_exec_path
        File.basename(exec_path, ".rb")
      end

      def read_commandline
        if ARGV[0] == 'start'
          start
        elsif ARGV[0] == 'stop'
          stop
        elsif ARGV[0] == 'restart'
          stop
          start
        else
          start_foreground
        end
      end

      def options
        return @options if @options
        args = ARGV.dup
        @options = Opener::Daemons::OptParser.parse!(args)
      end


      def pid_path
        return @pid_path unless @pid_path.nil?
        @pid_path = if @options[:pid]
                      File.expand_path(@options[:pid])
                    elsif @options[:pidpath]
                      File.expand_path(File.join(@options[:pidpath], "#{name}.pid"))
                    else
                      "/var/run/#{File.basename($0, ".rb")}.pid"
                    end
      end

      def create_pid(pid)
        begin
          open(pid_path, 'w') do |f|
            f.puts pid
          end
        rescue => e
          STDERR.puts "Error: Unable to open #{pid_path} for writing:\n\t" +
            "(#{e.class}) #{e.message}"
          exit!
        end
      end

      def get_pid
        pid = false
        begin
          open(pid_path, 'r') do |f|
            pid = f.readline
            pid = pid.to_s.gsub(/[^0-9]/,'')
          end
        rescue => e
          STDOUT.puts "Info: Unable to open #{pid_path} for reading:\n\t" +
            "(#{e.class}) #{e.message}"
        end


        if pid
          return pid.to_i
        else
          return nil
        end
      end

      def remove_pidfile
        begin
          File.unlink(pid_path)
        rescue => e
          STDERR.puts "ERROR: Unable to unlink #{path}:\n\t" +
            "(#{e.class}) #{e.message}"
          exit
        end
      end

      def process_exists?
        begin
          pid = get_pid
          return false unless pid
          Process.kill(0, pid)
          true
        rescue Errno::ESRCH, TypeError # "PID is NOT running or is zombied
          false
        rescue Errno::EPERM
          STDERR.puts "No permission to query #{pid}!";
          false
        rescue => e
          STDERR.puts "Error: Unable to determine status for pid: #{pid}.\n\t" +
            "(#{e.class}) #{e.message}"
          false
        end
      end

      def stop
        begin
          pid = get_pid
          STDOUT.puts "Stopping pid: #{pid}"
          while true do
            Process.kill("TERM", pid)
            Process.wait(pid)
            sleep(0.1)
          end
        rescue Errno::ESRCH # no more process to kill
          remove_pidfile
          STDOUT.puts 'Stopped the process'
        rescue => e
          STDERR.puts "Unable to terminate process: (#{e.class}) #{e.message}"
        end
      end

      def start
        if process_exists?
          STDERR.puts "Error: The process #{name} already running. Restarting the process"
          stop
        end

        STDOUT.puts "Starting DAEMON"
        pid = Spoon.spawnp exec_path, *ARGV
        STDOUT.puts "Started DAEMON"
        create_pid(pid)
        begin
          Process.setsid
        rescue Errno::EPERM => e
          STDERR.puts "Process.setsid not permitted on this platform, not critical. Continuing normal operations.\n\t (#{e.class}) #{e.message}"
        end
        File::umask(0)
      end

      def start_foreground
        exec [exec_path, ARGV].flatten.join(" ")
      end

      def identify(string)
        string.gsub(/\W/,"-").gsub("--","-")
      end
    end
  end
end
