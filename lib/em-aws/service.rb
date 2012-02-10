require 'em-http'
require 'em-aws/inflections'
require 'em-aws/request'

module EventMachine
  module AWS
    
    # Wraps an instance of EM::HttpRequest and applies logic to sign requests, perform retries, and
    # extract parameters from the response. This is an abstract base class; subclasses must declare
    # their service names, API versions, and mix in the proper protocol modules (Query or REST).
    class Service
      API_VERSION = nil   # Subclasses should override this
      
      include Inflections
      
      attr_reader :aws_access_key_id,
                  :aws_secret_access_key,
                  :region,
                  :ssl,
                  :options
      
      def initialize(options = {})
        @aws_access_key_id = options.delete(:aws_access_key_id) || EventMachine::AWS.aws_access_key_id
        @aws_secret_access_key = options.delete(:aws_secret_access_key) || EventMachine::AWS.aws_secret_access_key

        @region = options.delete(:region) || EventMachine::AWS.region
        if options.has_key?(:ssl)
          @ssl = options.delete(:ssl)
        else
          @ssl = EventMachine::AWS.ssl
        end
        @endpoint = options.delete(:endpoint)
        @options = options
      end
      
      def service
        self.class.name[/.*::(?<class>.+)/, :class].downcase
      end
      
      def endpoint
        @endpoint ||= "#{ssl ? 'https' : 'http'}://#{service}.#{region}.amazonaws.com/"
      end
      
      protected
      
      def send_request(request, &block)
        if request.method == :get
          http_request = EventMachine::HttpRequest.new(endpoint).get query: request.params
        else
          http_request = EventMachine::HttpRequest.new(endpoint).send request.method, body: request.params
        end

        http_request.errback do |raw_response|
          puts raw_response.response_header
          puts raw_response.response
        end
        
        http_request.callback do |raw_response|
          if raw_response.response_header.status == 200
            request.succeed success_response(raw_response)
          else
            request.fail failure_response(raw_response)
          end
        end
        request
      end
      
    end
  end
end