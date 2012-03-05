require 'em-aws/query'

module EventMachine
  module AWS
    class SNS < Service
      include Query
      
      API_VERSION = '2010-03-31'

      # @macro [attach] action
      #   Amazon API query. See Amazon's documentation for full details.
      #   @param [Hash] params Parameters passed to Amazon; see below
      #   @yield Runs the given block as a callback on successful response
      #   @yieldparam [QueryResult] response Response object containing data from Amazon
      #   @return [EventMachine::AWS::Request] Request object that (eventually) encapsulates the response      
      # @request [String] :name Topic name (letters, numbers and hyphens only)
      # @response [String] :topic_arn Amazon Resource Name (ARN) assigned to the created topic
      action :create_topic
      
      # 
      action :list_topics
      
      # @request [String] :topic_arn Topic ARN
      action :delete_topic
    end
  end
end