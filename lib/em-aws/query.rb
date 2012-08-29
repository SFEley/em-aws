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

      # {include:Service#initialize}
      def initialize(options = {})
        super
        @method = options.delete(:method) || :post
        @signer = SignatureV2.new(aws_access_key_id, aws_secret_access_key, method, url) if aws_access_key_id && aws_secret_access_key
      end

      # Prepares the parameters and makes the HTTP request to Amazon.
      # @param [Symbol, String] action The API method to be called
      # @param [optional, Hash] params Parameters to be passed to Amazon
      # @yield [response] A user-supplied block that will become a callback for the request
      # @yieldparam [QueryResult] Successful result data from Amazon
      def call(action, params = {}, &block)
        query = {
          'Action' => camelcase(action),
          'Version' => self.class::API_VERSION,
          'Timestamp' => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
          }
        query.merge! queryize_params(params)
        query.merge! @signer.signature(query) if @signer

        request = Request.new(self, method, query)
        request_id = "#{self.class.name}##{action} (#{request.object_id})"
        AWS.logger.info "Calling #{request_id}"
        AWS.logger.debug "#{request_id} params: #{query}"

        request.callback(&block) if block

        if AWS.logger.info?
          request.callback do |r|
            duration = Time.now - request.start_time
            AWS.logger.info "Completed #{request_id} in #{duration} seconds"
            AWS.logger.debug "#{request_id} result: #{r.result}"
          end

          request.errback do |r|
            duration = Time.now - request.start_time
            AWS.logger.info "Failed #{request_id} in #{duration} seconds"
            AWS.logger.debug "#{request_id} result: #{r.result}"
          end
        end

        handle_request(request)

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

      module ClassMethods
        # A DSL macro that allows Amazon API actions to be easily declared and documented.
        # Wraps the #call method and allows transformation of input or output.
        # @param [Symbol] name The action to be called
        # @param [optional, Hash] options
        # @option options [Proc] :filter_params A lambda that performs in-place transformations on the parameters
        # @option options [Symbol] :single_param If an action takes a single value, provide the AWS parameter name for it and a hash will be unnecessary
        def action(name, options={})
          filter_params = options[:filter_params]
          filter_response = options[:filter_response]
          single_param = options[:single_param]

          define_method(name) do |params={}, &block|
            if single_param and !params.is_a?(Hash)
              params = {single_param => params}
            end
            filter_params[params] if filter_params

            if filter_response
              request = call name, params, &filter_response
              request.callback &block
              request
            else
              call name, params, &block
            end
          end

        end
      end

      def self.included(receiver)
        receiver.extend ClassMethods
      end

    end
  end
end
