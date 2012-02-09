require 'em-http'
require 'em-aws/inflections'
require 'em-aws/query/signature_v2'
require 'em-aws/query/request'
require 'em-aws/query/success_response'
require 'em-aws/query/error_response'

module EventMachine
  module AWS
    
    # Wraps an instance of EM::HttpRequest and applies logic to sign requests, perform retries, and
    # extract parameters from the response.
    class Query
      API_VERSION = nil   # Subclasses should override this
      SIGNER_CLASS = SignatureV2
      
      include Inflections
      
      attr_reader :aws_access_key_id,
                  :aws_secret_access_key,
                  :region,
                  :ssl,
                  :method,
                  :options
      
      def initialize(options = {})
        @method = options.delete(:method) || :post
        @region = options.delete(:region) || EventMachine::AWS.region
        if options.has_key?(:ssl)
          @ssl = options.delete(:ssl)
        else
          @ssl = EventMachine::AWS.ssl
        end
        @endpoint = options.delete(:endpoint)
        @options = options
        @connection = EM::HttpRequest.new(endpoint)
        
        # Make an authenticator class only if credentials are given
        @aws_access_key_id = options.delete(:aws_access_key_id) || EventMachine::AWS.aws_access_key_id
        @aws_secret_access_key = options.delete(:aws_secret_access_key) || EventMachine::AWS.aws_secret_access_key
        @signer = self.class::SIGNER_CLASS.new(aws_access_key_id, aws_secret_access_key, method, endpoint) if aws_access_key_id && aws_secret_access_key

      end
      
      def service
        self.class.name[/.*::(?<class>.+)/, :class].downcase
      end
      
      def endpoint
        @endpoint ||= "#{ssl ? 'https' : 'http'}://#{service}.#{region}.amazonaws.com/"
      end

      def call(action, params = {}, &block)
        query = {
          'Action' => camelcase(action), 
          'Version' => self.class::API_VERSION,
          'Timestamp' => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
          }
        query.merge! camelkeys(params)
        query.merge! @signer.signature(query) if @signer

        request = Request.new(self, query)
        send_request(request, &block)
      end
      
      protected
      
      def send_request(request, &block)
        if method == :get
          http_request = EventMachine::HttpRequest.new(endpoint).get query: request.params
        else
          http_request = EventMachine::HttpRequest.new(endpoint).send method, body: request.params
        end

        http_request.errback do |raw_response|
          puts raw_response.response_header
          puts raw_response.response
        end
        
        if block
          http_request.callback do |raw_response|
            # raw_response is the object returned by EM::HttpClient.
            block.call SuccessResponse.new(raw_response)
          end
        end
        http_request
      end
      
    end
  end
end