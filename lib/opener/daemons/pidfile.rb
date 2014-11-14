module Opener
  module Daemons
    ##
    # Class for writing and retrieving PID files as well as managing the
    # associated process.
    #
    # @!attribute [r] path
    #  The path to store the PID in.
    #  @return [String]
    #
    class Pidfile
      attr_reader :path

      ##
      # @param [String] path
      #
      def initialize(path)
        @path = path
      end

      ##
      # Writes the given process ID to `@path`.
      #
      # @param [Fixnum] id
      #
      def write(id)
        File.open(path, 'w') do |handle|
          handle.write(id.to_s)
        end

      # Kill the process immediately if we couldn't write the PID
      rescue Errno::ENOENT, Errno::EPERM => error
        Process.kill('KILL', id)
      end

      ##
      # Reads and returns the process ID.
      #
      # @return [Fixnum]
      #
      def read
        return File.read(path).to_i
      end

      ##
      # Removes the associated file, if it exists.
      #
      def unlink
        File.unlink(path) if File.file?(path)
      end

      ##
      # Terminates the process by sending it the TERM signal and waits for it to
      # shut down.
      #
      def terminate
        id = read

        begin
          Process.kill('TERM', id)
          Process.wait(id)
        rescue Errno::ESRCH, Errno::ECHILD
          # Process terminated, yay. Any other error is re-raised.
        end
      end

      ##
      # Returns `true` if the associated process is alive.
      #
      # @return [TrueClass|FalseClass]
      #
      def alive?
        id = read

        begin
          Process.kill(0, id)

          return true
        rescue Errno::ESRCH, Errno::EPERM
          return false
        end
      end
    end # Pidfile
  end # Daemons
end # Opener
