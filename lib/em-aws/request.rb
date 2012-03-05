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
      
      attr_reader :service, :method, :params, :response, :start_time
      attr_accessor :attempts
      
      def initialize(service, method, params)
        @service, @method, @params = service, method, params
        @start_time = Time.now
        @attempts = 0
        
        self.callback {|r| @response = r}
        self.errback {|r| @response = r}
      end
      
      def finished?
        !response.nil?
      end
      
      def success?
        response and response.success?
      end
      
      def status
        response and response.status
      end
      
      def method_missing(name, *args, &block)
        if response
          response.send name, *args, &block
        else
          super
        end
      end
      
    end
    
  end
end