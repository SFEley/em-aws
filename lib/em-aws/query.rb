require 'em-http'
require 'em-aws/inflections'
require 'em-aws/request'
require 'em-aws/query/signature_v2'
require 'em-aws/query/query_result'
require 'em-aws/query/query_failure'
require 'em-aws/query/query_params'

module EventMachine
  module AWS
    
    # Plugs in the proper signing functions and call functionality for the Amazon Query Protocol.
    # Almost every Amazon service (with the exception of S3) uses this protocol.
    module Query
      API_VERSION = nil   # Subclasses should override this
      include Inflections
      include QueryParams
      
      attr_reader :method
      
      def initialize(options = {})
        super
        @method = options.delete(:method) || :post
        @signer = SignatureV2.new(aws_access_key_id, aws_secret_access_key, method, url) if aws_access_key_id && aws_secret_access_key
      end
      
      def call(action, params = {}, &block)
        query = {
          'Action' => camelcase(action), 
          'Version' => self.class::API_VERSION,
          'Timestamp' => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
          }
        query.merge! queryize_params(params)
        query.merge! @signer.signature(query) if @signer

        request = Request.new(self, method, query)
        request.callback(&block) if block
        
        send_request(request)
      end
      
      # Returns an instance of QueryResult with the XML from the
      # results parsed into regular attributes.
      def success_response(raw_response)
        QueryResult.new raw_response
      end
      
      # Returns an instance of QueryFailure with the relevant error information from Amazon.
      def failure_response(raw_response)
        QueryFailure.new raw_response
      end
      
      def method_missing(name, *args, &block)
        if EventMachine.reactor_running?
          call name, *args, &block
        else
          response = nil
          EventMachine.run do
            request = call name, *args, &block
            request.callback {|r| response = r; EventMachine.stop}
            request.errback {|r| r.exception!}
          end
          response
        end
      end
            
    end
  end
end