require 'em-http'

module EventMachine
  module AWS
    
    # Wraps an instance of EM::HttpRequest and applies logic to sign requests, perform retries, and
    # extract parameters from the response.
    class Query
      def initialize(options = {})
        @region = options.delete(:region)
        @ssl = options.delete(:ssl)
        @endpoint = options.delete(:endpoint)
      end
      
      
      
      def region
        @region ||= EventMachine::AWS.region
      end
      
      def ssl
        if @ssl.nil?
          @ssl = EventMachine::AWS.ssl
        else
          @ssl
        end
      end
      
      def service
        self.class.name[/.*::(?<class>.+)/, :class].downcase
      end
      
      def endpoint
        @endpoint ||= "#{ssl ? 'https' : 'http'}://#{service}.#{region}.amazonaws.com/"
      end
    end
  end
end