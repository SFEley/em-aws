module EventMachine
  module AWS
    class Query
    
      # Exposes the result values from an Amazon Query Protocol XML response.
      # This is an abstract base class; the interesting values come from
      # the subclasses SuccessResponse and ErrorResponse.
      class Response
        attr_reader :header, :xml
        
        def initialize(http_response)
          @header = http_response.response_header
          @xml = http_response.response
        end
        
        def status
          header.status
        end
      end
      
    end
  end
end