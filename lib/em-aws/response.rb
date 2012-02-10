require "em-aws"

module EventMachine
  module AWS
    # Exposes the result values from an Amazon Query Protocol XML response.
    # This is an abstract base class; the interesting values come from
    # the subclasses SuccessResponse and ErrorResponse.
    class Response
      attr_reader :header, :body
      
      def initialize(http_response)
        @header = http_response.response_header
        @body = http_response.response
      end
      
      def status
        header.status
      end
      
      # Must be overridden by subclasses. (An actual base Response instance is NOT a success.)
      def success?
        nil
      end
    end
    
    # Base class for responses which succeeded (i.e. Amazon did not send us an error).
    # Behavior may vary significantly based on subclass.
    class SuccessResponse < Response
      def success?
        true
      end
    end
    
    # Base class for responses which failed (either a network issue or an error from Amazon).
    # Failures raise an exception when you try to call any method other than inspecting the failure.
    # The specific exception is up to subclasses.
    class FailureResponse < Response
      attr_reader :error
      
      def initialize(http_response)
        super
        @error = http_response.error
      end
      
      def success?
        false
      end
      
      def exception
        AWS::Error.new "Request failure: #{@error}"
      end
    end
  end
end