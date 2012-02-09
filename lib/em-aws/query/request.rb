require 'eventmachine'
require 'em-aws/inflections'

module EventMachine
  module AWS
    class Query
      
      # A utility class that encapsulates a specific request with its parameters.
      # Users will rarely create a Request directly; you should instead
      # use the `#call` method on the relevant Service object.
      class Request
        include Deferrable
        include Inflections
        
        attr_reader :service, :params, :attempts, :response
        
        def initialize(service, params)
          @service, @params = service, params
          @attempts = 0
          
          self.callback {|r| @response = r}
        end
        
        def [](key)
          params[key] || params[camelcase(key)]
        end
        
        def finished?
          !response.nil?
        end
        
        def success?
          response.is_a?(SuccessResponse)
        end
      end
    end
  end
end