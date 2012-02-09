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
    class SuccessResponse < Response
      def success?
        true
      end
    end
    
    # Base class for responses which failed (either a network issue or an error from Amazon).
    class ErrorResponse < Response
      def success?
        false
      end
    end
  end
end