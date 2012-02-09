require 'em-http'
require 'em-aws/inflections'
require 'em-aws/request'
require 'em-aws/query/signature_v2'
require 'em-aws/query/query_result'
require 'em-aws/query/query_error'

module EventMachine
  module AWS
    
    # Plugs in the proper signing functions and call functionality for the Amazon Query Protocol.
    # Almost every Amazon service (with the exception of S3) uses this protocol.
    module Query
      API_VERSION = nil   # Subclasses should override this
      include Inflections
      
      attr_reader :method
      
      def initialize(options = {})
        super
        @method = options.delete(:method) || :post
        @signer = SignatureV2.new(aws_access_key_id, aws_secret_access_key, method, endpoint) if aws_access_key_id && aws_secret_access_key
      end
      
      def call(action, params = {}, &block)
        query = {
          'Action' => camelcase(action), 
          'Version' => self.class::API_VERSION,
          'Timestamp' => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
          }
        query.merge! camelkeys(params)
        query.merge! @signer.signature(query) if @signer

        request = Request.new(self, method, query)
        send_request(request, &block)
      end
      
      # Returns an instance of Query::SuccessResponse with the XML from the
      # results parsed into regular attributes.
      def success_response(raw_response)
        QueryResult.new raw_response
      end
      
    end
  end
end