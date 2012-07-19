require 'em-aws/query'
require 'em-aws/inflections'

module EventMachine
  module AWS
    class SNS < Service
      include Query
      extend Inflections

      API_VERSION = '2010-03-31'

      # @!group AWS Actions

      # @!method add_permission(request_params)
      # Modifies the Access Control List (ACL) of a single topic. Can allow one or more actions for one or more AWS accounts.
      #
      # Because the API for specifying multiple permissions is somewhat roundabout, **EM::AWS**
      # supports three different use patterns for adding permissions:
      #
      # @example Specify a single `:aws_account_id` and a single `:action_name` param:
      #   sns.add_permission topic_arn: 'arn:aws:sns:us-east-1:12345679012:My-Test-Topic',
      #       aws_account_id: 123456789012,
      #       action_name: :get_topic_attributes
      #
      # @example Assign an array for `:aws_account_id` and a corresponding array for `:action_name`:
      #   sns.add_permission topic_arn: 'arn:aws:sns:us-east-1:12345679012:My-Test-Topic',
      #       aws_account_id: [123456789012, 123456789012, 109876543210],
      #       action_name: [:subscribe, :get_topic_attributes, :subscribe]
      #
      # @example Specify a `:permissions` hash where each key is an AWS account ID and each value is a permission or array of permissions:
      #   sns.add_permission topic_arn: 'arn:aws:sns:us-east-1:12345679012:My-Test-Topic',
      #       permissions: {
      #           123456789012 => [:subscribe, :get_topic_attributes],
      #           109876543210 => :subscribe
      #       }
      #
      # @request [String] :topic_arn The topic whose ACL you wish to modify
      # @request [String] :label A unique name for the new policy statement
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

      # @!method confirm_subscription(request_params)
      # Verifies a subscription via token authentication. The `:subscribe` call must previously
      # have been made and a token sent to the given endpoint.
      #
      # @request [String] :topic_arn The topic being subscribed to
      # @request [String] :token A one-time token sent to the endpoint during the _Subscribe_ action
      # @request [optional, Boolean] :authenticate_on_unsubscribe If _true_, credentials for the subscriber or the topic owner must be given on an _Unsubscribe_ action
      #
      # @response [String] :subscription_arn Amazon Resource Name (ARN) assigned to the subscription
      action :confirm_subscription

      # @!method create_topic(request_params)
      # Creates the given topic. Amazon states that this action is idempotent: creating the same
      # topic multiple times will not produce an error.
      #
      # @request [String] :name Topic name (letters, numbers and hyphens only)
      # @response [String] :topic_arn Amazon Resource Name (ARN) assigned to the created topic
      action :create_topic

      # @!method delete_topic(request_params)
      # Deletes the given topic. Amazon states that this action is idempotent: deleting the same
      # topic multiple times will not produce an error.
      #
      # @request [String] :topic_arn Amazon Resource Name (ARN) assigned to the topic
      action :delete_topic

      # @!method get_subscription_attributes(request_params)
      # Returns the properties of the given subscription. Note that the attributes returned are
      # given directly at the top level of the response object; there is no `:attributes` attribute.
      #
      # @request [String] :subscription_arn Amazon Resource Name (ARN) assigned to the subscription
      # @response [Boolean] :confirmation_was_authenticated Whether the _ConfirmSubscription_ action was signed with the owner's credentials
      # @response [String] :delivery_policy Explicit delivery policy of the subscription in JSON form
      # @response [String] :effective_delivery_policy Delivery policy including topic and system defaults in JSON form
      # @response [String] :owner AWS account ID of the subscription's owner
      # @response [String] :subscription_arn Amazon Resource Name (ARN) assigned to the subscription
      # @response [String] :topic_arn Amazon Resource Name (ARN) assigned to the topic
      action :get_subscription_attributes

      # @!method get_topic_attributes(request_params)
      # Returns the properties of the given topic. Note that the attributes returned are
      # given directly at the top level of the response object; there is no `:attributes` attribute.
      #
      # @request [String] :topic_arn Amazon Resource Name (ARN) assigned to the topic
      # @response [String] :delivery_policy Delivery policy of the topic in JSON form
      # @response [String] :display_name Topic name used in "From" field for email notifications
      # @response [String] :effective_delivery_policy Delivery policy including system defaults in JSON form
      # @response [String] :owner AWS account ID of the topic's owner
      # @response [String] :policy Topic's access control policy in JSON form
      # @response [Integer] :subscriptions_confirmed Number of confirmed subscriptions to this topic
      # @response [Integer] :subscriptions_deleted Number of deleted subscriptions to this topic
      # @response [Integer] :subscriptions_pending Number of not-yet-confirmed subscriptions to this topic
      # @response [String] :topic_arn Amazon Resource Name (ARN) assigned to the topic
      action :get_topic_attributes

      # @!method list_subscriptions(request_params)
      # Returns the requester's active subscriptions. The `:subscriptions` attribute contains an array of
      # hashes; see below.
      #
      # @request [optional, String] :next_token Continuation token from a prior `:list_subscriptions` request
      # @response [String] :next_token Continuation token if there are more subscriptions than listed in one response
      # @response [Array] :subscriptions Subscription list. Each element is a hash containing a subscription's
      #   `:topic_arn`, `:protocol`, `:subscription_arn`, `:owner`, and `:endpoint`.
      action :list_subscriptions

      # @!method list_subscriptions_by_topic(request_params)
      # Returns the active subscriptions for a given topic. The `:subscriptions` attribute contains an array of
      # hashes; see below.
      #
      # @request [optional, String] :next_token Continuation token from a prior `:list_subscriptions_by_topic` request
      # @request [String] :topic_arn Amazon Resource Name (ARN) assigned to the topic
      # @response [String] :next_token Continuation token if there are more subscriptions than listed in one response
      # @response [Array] :subscriptions Subscription list. Each element is a hash containing a subscription's
      #   `:topic_arn`, `:protocol`, `:subscription_arn`, `:owner`, and `:endpoint`.
      action :list_subscriptions_by_topic

      # @!method list_topics(request_params)
      # Returns the requester's topics. The `:topics` attribute contains an array of strings, each of which is
      # the topic's ARN.
      #
      # @request [optional, String] :next_token Continuation token from a prior `:list_topics` request
      # @response [String] :next_token Continuation token if there are more subscriptions than listed in one response
      # @response [Array] :topics Topic list. Each element is an Amazon Resource Name (ARN) of a topic.
      action :list_topics

      # @!method publish(request_params)
      # Send a message to a topic, to be delivered to all of a topic's subscribers. There are two valid formats
      # for the `:message` parameter:
      #
      # 1. If a string is given, the message will be delivered to all subscribers regardless of delivery protocol.
      #   The string _must_ be valid UTF-8 and have a maximum of 8192 bytes (not characters).
      # 2. If a hash is given, the message is treated as having multiple formats.  Keys should correspond to
      #   valid SNS transport protocols, and _must_ include a
      #   `:default` key. Each value will be sent as the message for the corresponding protocol, with unstated
      #   protocols receiving the "default" message. The sum of _all_ message formats must be less than 8192 bytes after
      #   JSON conversion.
      #
      # This behavior abstracts the need to explicitly convert a multi-format message to JSON or to provide a
      # `:message_structure` parameter.  Valid protocol values are `:http`, `:https`, `:email`, `:email_json`,
      # `:sms`, and `:sqs`. All protocols except for `:email` and `:sms` will deliver the message to
      # subscribers as a JSON object.
      #
      # @example Single format message
      #     sns.publish topic_arn: 'arn:aws:sns:us-east-1:12345679012:My-Test-Topic',
      #       subject: "Test thing",
      #       message: "We're testing our Awesome Test Topic™. Have a nice day.☺"
      #
      # @example Multi-format message
      #     sns.publish topic_arn: 'arn:aws:sns:us-east-1:12345679012:My-Test-Topic',
      #       subject: "Test thing",
      #       message: {
      #           default: "We're testing our Awesome Test Topic™. Have a nice day.☺",
      #           sms: "Topic test! Your phone should be beeping!",
      #           email: "Hello friend, we're testing our Awesome Test Topic™. Please don't mark this as spam."
      #       }
      #
      # @request [String] :topic_arn Amazon Resource Name (ARN) assigned to the topic
      # @request [String, Hash] :message Message text or multi-format hash (see above)
      # @request [optional, String] :subject Subject line for emails (also included in JSON messages)
      # @request [optional, "json"] :message_structure Specify JSON multi-format text _(not needed if you use a message hash; see above)_
      # @response [String] :message_id Unique identifier for the published message
      action :publish

      # @!method remove_permission(request_params)
      # Removes a given set of permissions from a topic's access control policy. The `:label` must be the
      # one chosen when the permission was added with the _AddPermission_ action.
      #
      # @request [String] :label The unique label of the permission statement
      # @request [String] :topic_arn Amazon Resource Name (ARN) assigned to the topic
      action :remove_permission

      # @!method set_subscription_attributes(request_params)
      # Sets a single attribute of the subscription. In this version of the API, only the 'DeliveryPolicy'
      # attribute can be set (and only if the topic allows subscription overrides). The policy value must
      # be valid JSON and can be any subset of the following structure:
      #
      #     {
      #       "healthyRetryPolicy":
      #       {
      #         "minDelayTarget":  <int>,
      #         "maxDelayTarget": <int>,
      #         "numRetries": <int>,
      #         "numMaxDelayRetries": <int>,
      #         "backoffFunction": "<linear|arithmetic|geometric|exponential>"
      #       },
      #         "throttlePolicy":
      #         {
      #           "maxReceivesPerSecond": <int>
      #         }
      #     }
      #
      # @example
      #     sns.set_subscription_attributes attribute_name: 'DeliveryPolicy',
      #       attribute_value: '{"throttlePolicy": {"maxReceivesPerSecond": 3}}',
      #       subscription_arn: 'arn:aws:sns:us-east-1:12345679012:My-Test-Topic:80289ba6-0fd4-4079-afb4-cd8c8260f0ca'
      #
      # @request [String] :attribute_name Attribute to set. *The only valid value is "DeliveryPolicy".*
      # @request [String] :attribute_value New value for attribute
      # @request [String] :subscription_arn Amazon Resource Name (ARN) assigned to the subscription
      action :set_subscription_attributes

      # @!method set_topic_attributes(request_params)
      # Sets a single attribute of the topic. In this version of the API, the attributes that can be set
      # are:
      #
      # * 'DisplayName' - Used in SMS and email messages
      # * 'Policy' - Access control policy in JSON format
      # * 'DeliveryPolicy' - Default delivery settings in JSON format
      #
      # For the 'DeliveryPolicy' attribute, the value must be valid JSON and can be any subset of the
      # following structure:
      #
      #     {
      #       "http":
      #         {
      #           "defaultHealthyRetryPolicy":
      #             {
      #               "minDelayTarget":  <int>,
      #               "maxDelayTarget": <int>,
      #               "numRetries": <int>,
      #               "numMaxDelayRetries": <int>,
      #               "backoffFunction": "<linear|arithmetic|geometric|exponential>"
      #             },
      #           "defaultThrottlePolicy":
      #             {
      #               "maxReceivesPerSecond": <int>
      #             },
      #           "disableSubscriptionOverrides": <boolean>
      #         }
      #     }
      #
      # The value of the 'Policy' attribute is left as an exercise for the masochistic reader.
      #
      # @example
      #     sns.set_topic_attributes attribute_name: 'DeliveryPolicy',
      #       attribute_value: '{"defaultHealthyRetryPolicy": {"numMaxDelayRetries": 20}}',
      #       topic_arn: 'arn:aws:sns:us-east-1:12345679012:My-Test-Topic'
      #
      # @request ["DeliveryPolicy | Policy | DisplayName" ] :attribute_name Attribute to set
      # @request [String] :attribute_value New value for attribute
      # @request [String] :topic_arn Amazon Resource Name (ARN) assigned to the topic
      action :set_topic_attributes

      # @!method subscribe(request_params)
      # Registers a new endpoint with the topic. In most cases the endpoint owner must call the
      # _ConfirmSubscription_ action using the token received at the endpoint to start receiving
      # notifications. Confirmation tokens are valid for three days.
      #
      # Valid protocol values and their acceptable endpoints are:
      #
      # * `:http` - Endpoint must be a URL beginning with 'http://'
      # * `:https` - Endpoint must be a URL beginning with 'https://'
      # * `:email` - Endpoint must be a valid email address
      # * `:email_json` - Endpoint must be a valid email address
      # * `:sms` - Endpoint must be a phone number
      # * `:sqs` - Endpoint must be the ARN of an [Amazon SQS](http://aws.amazon.com/sqs) queue
      #
      # @request [String] :topic_arn Amazon Resource Name (ARN) assigned to the topic
      # @request [Symbol, String] :protocol Message delivery type (see above)
      # @request [String] :endpoint Message receiver (see above)
      # @response [String] :subscription_arn Amazon Resource Name (ARN) of the subscription,
      #   _if_ it was created without confirmation required
      action :subscribe

      # @!method unsubscribe(request_params)
      # Deletes the given subscription. The call need not be authenticated with credentials if the
      # subscription was confirmed with `:authenticate_on_unsubscribe` set to _false_.
      #
      # @request [String] :subscription_arn Amazon Resource Name (ARN) assigned to the subscription
      action :unsubscribe

      # @!endgroup
    end

  end
end
