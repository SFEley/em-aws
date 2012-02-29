require 'em-http'
require 'em-aws/inflections'
require 'em-aws/request'

module EventMachine
  module AWS
    
    # Wraps an HTTP connection to Amazon and applies logic to sign requests, perform retries, and
    # extract parameters from the response. This is an abstract base class; subclasses must mix in
    # the necessary behavior for authentication, transforming parameters and responses, etc.
    # @see Query
    class Service
      include Inflections
      
      # Defaults to values from {AWS} module attributes
      attr_reader :aws_access_key_id,
                  :aws_secret_access_key,
                  :region,
                  :ssl
      
      # Used in some AWS services to point to the resource. (Most services use the '/' root path.)
      attr_reader :path
      
      # Create a new instance for any change in credentials or endpoint. Options can be set only on
      # initialization.
      # @param [Hash] options All are optional; will default to {AWS} module settings if not provided
      # @option options [String]  :aws_access_key_id Authentication credentials
      # @option options [String]  :aws_secret_access_key Authentication credentials
      # @option options [String]  :region Used to construct the endpoint URL; defaults to **'us-east-1'**
      # @option options [Boolean] :ssl Used to construct the endpoint URL; defaults to **true** (https)
      # @option options [String]  :path Used to construct the endpoint URL; defaults to **'/'** (root path)
      # @option options [String]  :url 
      def initialize(options = {})
        @aws_access_key_id = options[:aws_access_key_id] || EventMachine::AWS.aws_access_key_id
        @aws_secret_access_key = options[:aws_secret_access_key] || EventMachine::AWS.aws_secret_access_key

        @region = options[:region] || EventMachine::AWS.region
        if options.has_key?(:ssl)
          @ssl = options[:ssl]
        else
          @ssl = EventMachine::AWS.ssl
        end
        @path = options[:path]
        @url = options[:url]
      end
      
      # Derived by default from the class name
      # @attribute [r]
      def service
        self.class.name[/.*::(?<class>.+)/, :class].downcase
      end
      
      # Constructed by default from the _ssl_, _service_, _region_ and _path_ values
      # @attribute [r]
      def url
        @url ||= "#{ssl ? 'https' : 'http'}://#{service}.#{region}.amazonaws.com/#{path}"
      end
      
      private
      
      # Fake synchronous behavior if EM isn't running
      def handle_request(request)
        if EventMachine.reactor_running?
          send_request(request)
        else
          response = nil
          EventMachine.run do
            send_request(request)
            request.callback {|r| response = r}
            request.callback {|r| EventMachine.stop}
            request.errback {|r| r.exception!}
          end
          response
        end
      end
      
      def send_request(request)
        request.attempts += 1
        http_client = EventMachine::HttpRequest.new(self.url)

        if request.method == :get
          http_request = http_client.get query: request.params
        else
          http_request = http_client.send request.method, body: request.params
        end

        http_request.errback do |raw_response|
          # Send again until retry limit is exceeded
          if request.attempts <= EM::AWS.retries
            AWS.logger.warn("HTTP client error; retry #{request.attempts} of #{EM::AWS.retries}")
            EM.add_timer(next_delay(request.attempts)) {send_request request}
          else
            f = FailureResponse.new(raw_response)
            AWS.logger.error("HTTP client error; gave up after #{EM::AWS.retries} retries: #{f.error}")
            request.fail f
          end
        end
        
        http_request.callback do |raw_response|
          case raw_response.response_header.status
          when 200
            request.succeed success_response(raw_response)
          when 500, 502, 503, 504
            if request.attempts <= EM::AWS.retries
              AWS.logger.warn("Amazon #{raw_response.response_header.status} error; retry #{request.attempts} of #{EM::AWS.retries}")
              EM.add_timer(next_delay(request.attempts)) {send_request request}
            else
              f = failure_response(raw_response)
              AWS.logger.error("Amazon #{raw_response.response_header.status} error; gave up after #{EM::AWS.retries} retries: #{f.error}")
              request.fail f
            end
          else
            f = failure_response(raw_response)
            AWS.logger.error("Amazon #{raw_response.response_header.status} error: #{f.error}")
            request.fail f
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