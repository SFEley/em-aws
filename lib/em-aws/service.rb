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
                  :path,
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
        @url = options.delete(:url)
        @options = options
      end
      
      def service
        self.class.name[/.*::(?<class>.+)/, :class].downcase
      end
      
      def url
        @url ||= "#{ssl ? 'https' : 'http'}://#{service}.#{region}.amazonaws.com/#{path}"
      end
      
      private
      
      def send_request(request)
        request.attempts += 1

        if request.method == :get
          http_request = EventMachine::HttpRequest.new(self.url).get query: request.params
        else
          http_request = EventMachine::HttpRequest.new(self.url).send request.method, body: request.params
        end

        http_request.errback do |raw_response|
          # Send again until retry limit is exceeded
          if request.attempts <= EM::AWS.retries
            EM.add_timer(next_delay(request.attempts)) {send_request request}
          else
            request.fail FailureResponse.new(raw_response)
          end
        end
        
        http_request.callback do |raw_response|
          case raw_response.response_header.status
          when 200
            request.succeed success_response(raw_response)
          when 500, 502, 503, 504
            if request.attempts <= EM::AWS.retries
              EM.add_timer(next_delay(request.attempts)) {send_request request}
            else
              request.fail failure_response(raw_response)
            end
          else
            request.fail failure_response(raw_response)
          end
        end

        request
      end
      
      # Abstract stub; should be overridden in subclasses or submodules
      def success_response(response)
        response
      end

      # Abstract stub; should be overridden in subclasses or submodules
      def failure_response(response)
        response
      end
      
      # (Yes, it's a Fibonacci sequence generator.)
      def next_delay(n)
        a, b = 0, 1
        n.times {a, b = b, a+b}
        a
      end
        
      
      
    end
  end
end