require 'em-aws/query'

module EventMachine
  module AWS
    class SNS < Service
      include Query
      
      API_VERSION = '2010-03-31'
      
      # @macro [attach] action
      #   Amazon API query. See AWS documentation for details.
      # @request :name Topic name (letters, numbers and hyphens only)
      # @response [String] :topic_arn Amazon Resource Name (ARN) assigned to the created topic
      action :create_topic
      
      
      action :list_topics
      action :delete_topic
    end
  end
end