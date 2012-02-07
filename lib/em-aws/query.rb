require 'em-http'
require 'em-aws/protocol/signature_v2'

module EventMachine
  module AWS
    
    # Wraps an instance of EM::HttpRequest and applies logic to sign requests, perform retries, and
    # extract parameters from the response.
    class Query
      API_VERSION = nil   # Subclasses should override this
      SIGNER_CLASS = AWS::SignatureV2
      
      attr_reader :aws_access_key_id,
                  :aws_secret_access_key,
                  :connection,
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
        if method == :get
          connection.get query: query
        else
          connection.send method, body: query
        end
      end
      
      protected
      
      def snakecase(name)
        # Adapted from ActiveSupport's #underscore method
        name.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
      end
      
      def camelcase(name)
        # Adapted from ActiveSupport's #camelize method
        name.to_s.gsub(/(?:^|_)(.)/) { $1.upcase }
      end
      
      # Camelize key names for Amazon conventions 
      def camelkeys(hash)
        out = {}
        hash.each do |k, v|
          out[camelcase(k)] = v
        end
        out
      end
      
    end
  end
end