require "logger"

module EventMachine
  module AWS
    module Logger

      # An instance of the standard Ruby Logger or some compatible object.
      # Defaults to logging warnings & above to STDERR.  You can supply
      # your own object, but if you do, the 'logfile' and 'loglevel' attributes
      # will no longer apply.
      attr_writer :logger

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

      # The filename or IO object used for logging. Defaults to STDERR. Changing it will
      # create a new logger.
      # @attribute [w] logfile
      def logfile=(dev)
        @logfile = dev
        @logger = nil
      end

      # The filename or IO object used for logging. Defaults to STDERR. Changing it will
      # create a new logger.
      # @attribute [r] logfile
      def logfile
        @logfile ||= STDERR
      end

      # Minimum severity level for logging. Defaults to WARN.
      # @attribute [r] loglevel
      def loglevel
        @loglevel ||= ::Logger::WARN
      end

      # Minimum severity level for logging. Defaults to WARN.
      # @attribute [w] loglevel
      def loglevel=(level)
        @loglevel = logger.level = level
      end


    end
  end
end
