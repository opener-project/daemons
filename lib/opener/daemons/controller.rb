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
      attr_reader :name

      def initialize(options={})
        @name = identify(options.fetch(:name))
        read_commandline
      end

      def read_commandline
        if ARGV[0] == 'start'
          start
        elsif ARGV[0] == 'stop'
          stop
        elsif ARGV[0] == 'restart'
          stop
          start
        elsif ARGV[0] == '-h'
          Opener::OptParser.parse!(ARGV)
        else
          puts "Usage: #{name} <start|stop|restart> [options]"
          puts "Or for help use: #{name} -h"
          exit!
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
          STDERR.puts "Error: Unable to open #{pid_path} for reading:\n\t" +
            "(#{e.class}) #{e.message}"
        end

        pid.to_i
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
        rescue => e
          STDERR.puts "(#{e.class}) #{e.message}:\n\t" +
            "Unable to determine status for #{pid}."
            false
        end
      end

      def stop
        begin
          pid = get_pid
          STDOUT.puts "pid : #{pid}"
          while true do
            Process.kill("TERM", pid)
            Process.wait(pid)
            sleep(0.1)
          end
        rescue Errno::ESRCH # no more process to kill
          remove_pidfile
          STDOUT.puts 'Stopped the process'
        rescue => e
          STDERR.puts "unable to terminate process: (#{e.class}) #{e.message}"
        end
      end

      def start
        if process_exists?
          STDERR.puts "The process #{exec} already running. Restarting the process"
          stop
        end

        pid = Spoon.spawnp exec, *ARGV
        create_pid(pid)
        Process.setsid

        Dir::chdir(WORK_PATH)
        File::umask(0)
      end

      def exec
        file = File.expand_path("../../exec/#{name}.rb", __FILE__)
        "ruby #{file} #{ARGV.join(" ")}"
      end

      def pid_path
        return @pid_path unless @pid_path.nil?
        path = ENV["PID_PATH"] ||= "/var/run/"
        @pid_path = File.join(path, "#{name}.pid")
      end

      def identify(string)
        string.gsub(/\W/,"-").gsub("--","-")
      end
    end
  end
end
