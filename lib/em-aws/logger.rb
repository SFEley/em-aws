require "logger"

module EventMachine
  module AWS
    module Logger
      attr_writer :logger
      
      # Resets the logger with the given IO object.
      def logfile=(dev)
        @logfile = dev
        @logger = nil
      end
      
      # The IO object used for logging. Defaults to STDERR.
      def logfile
        @logfile ||= STDERR
      end
      
      # Minimum severity level for logging. Defaults to WARN.
      def loglevel
        @loglevel ||= ::Logger::WARN
      end
      
      # Set the logging severity level.
      def loglevel=(level)
        @loglevel = logger.level = level
      end
      
      # An instance of the standard Ruby Logger or some compatible object.
      # Defaults to logging warnings & above to STDERR.  You can supply
      # your own object, but if you do, the 'logfile' and 'loglevel' attributes
      # will no longer apply.
      def logger
        @logger ||= begin
          l = ::Logger.new logfile
          l.level = loglevel
          l.progname = "EM::AWS"
          l
        end
      end
      
    end
  end
end