require 'em-aws/query'
require 'em-aws/inflections'

module EventMachine
  module AWS
    class SNS < Service
      include Query
      extend Inflections
      
      API_VERSION = '2010-03-31'

      # Modifies the Access Control List (ACL) of a single topic. Can allow one or more actions for one or more AWS accounts.
      # 
      # Because the API for specifying multiple permissions is somewhat roundabout, **EM::AWS**
      # supports three different use patterns for adding permissions:
      # 
      # @example Specify a single `:aws_account_id` and a single `:action_name` param:
      #   sns.add_permission aws_account_id: 123456789012, action_name: :get_topic_attributes
      # 
      # @example Assign an array for `:aws_account_id` and a corresponding array for `:action_name`:
      #   sns.add_permission aws_account_id: [123456789012, 123456789012, 109876543210], action_name: [:subscribe, :get_topic_attributes, :subscribe]
      # 
      # @example Specify a `:permissions` hash where each key is an AWS account ID and each value is a permission or array of permissions:
      #   sns.add_permission permissions: {123456789012 => [:subscribe, :get_topic_attributes], 109876543210 => :subscribe}
      # 
      # @request [String] :topic_arn The topic whose ACL you wish to modify
      # @request [String] :label A _unique_ name for the new policy statement
      # @request [optional, Hash] :permissions Shortcut to map account IDs (keys) to one or more actions (values)
      # @request [optional, String, Integer, Array] :aws_account_id An ID or array of IDs for which new permissions should be added. _Required if `:permissions` is not used._
      # @request [optional, String, Symbol, Array] :action_name An action or list of actions to enable for the corresponding ID in `:aws_account_id`. _Required if `:permissions` is not used._
      action :add_permission, filter_params: ->(params) {
        params[:aws_account_id] = Array(params[:aws_account_id])
        params[:action_name] = Array(params[:action_name]).collect {|action| camelcase(action)}
        
        if permissions = params.delete(:permissions)
          permissions.each do |account, actions|
            Array(actions).each do |action|
              params[:aws_account_id] << account
              params[:action_name] << camelcase(action)
            end
          end
        end

        params["AWSAccountId.member"] = params.delete :aws_account_id
        params["ActionName.member"] = params.delete :action_name
      }

      # Verifies a subscription via token authentication. The `:subscribe` call must previously 
      # have been made and a token sent to the given endpoint.
      # 
      # @request [String] :topic_arn The topic being subscribed to
      # @request [String] :token A one-time token sent to the endpoint during the _Subscribe_ action
      # @request [optional, Boolean] :authenticate_on_unsubscribe If _true_, credentials for the subscriber or the topic owner must be given on an _Unsubscribe_ action
      # 
      # @response [String] :subscription_arn The ARN of the created subscription
      action :confirm_subscription

      # Creates the given topic
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