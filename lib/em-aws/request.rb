require 'eventmachine'
require 'em-aws/inflections'

module EventMachine
  module AWS
    
    # A utility class that encapsulates a specific request with its parameters.
    # Users will rarely create a Request directly; you should instead
    # use the `#call` method on the relevant Service object.
    class Request
      include Deferrable
      include Inflections
      
      attr_reader :service, :method, :params, :attempts, :response
      
      def initialize(service, method, params)
        @service, @method, @params = service, method, params
        @attempts = 0
        
        self.callback {|r| @response = r}
        self.errback {|r| @response = r}
      end
      
      def [](key)
        params[key] || params[camelcase(key)]
      end
      
      def finished?
        !response.nil?
      end
      
      def success?
        response && response.success?
      end
    end
    
  end
end