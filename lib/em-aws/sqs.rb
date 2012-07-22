require 'em-aws/query'

module EventMachine
  module AWS

    # NOTE: If you want to work with an individual queue, be sure to specify either the
    # :url parameter for the queue URL or the :queue_name.
    class SQS < Service
      include Query

      API_VERSION='2011-10-01'

      def queue_name
        url[/https?:\/\/.*?\/(.+)/,1]
      end

      # Retrieves an SQS object by queue name. Returns nil if the queue can't be found.
      def self.get(name)
        url, retriever = nil, self.new
        retriever.get_queue_url(queue_name: name) {|r| url = r.queue_url}
        if url
          self.new url: url
        else
          nil
        end
      end

      # Creates a queue by name and returns an SQS object pointing to it.  This operation
      # is idempotent (i.e. will return the same object) if the queue name already exists,
      # so long as no attributes are different.
      def self.create(name, attributes={})
        url, creator = nil, self.new
        creator.create_queue(queue_name: name, attributes: attributes) {|r| url = r.queue_url}
        if url
          self.new url: url
        else
          nil
        end
      end

      # @!method add_permission(request_params)
      # Adds one or more permissions on this queue for one or more accounts.
      # The permissions that can be added are as follows:
      #
      # * `:all` (the "*" wildcard to assign all permissions)
      # * `:send_message`
      # * `:receive_message`
      # * `:delete_message`
      # * `:change_message_visibility`
      # * `:get_queue_attributes`
      # * `:get_queue_url`
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
      # @request [String] :label A unique name for the new policy statement
      # @request [optional, Hash] :permissions Shortcut to map account IDs (keys) to one or more actions (values)
      # @request [optional, String, Integer, Array] :aws_account_id An ID or array of IDs for which new permissions should be added. _Required if `:permissions` is not used._
      # @request [optional, String, Symbol, Array] :action_name An action or list of actions to enable for the corresponding ID in `:aws_account_id`. _Required if `:permissions` is not used._
      action :add_permission, filter_params: ->(params){
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

        params["AWSAccountId"] = params.delete :aws_account_id
        params["ActionName"] = params.delete :action_name
      }

      # @!method change_message_visibility(request_params)
      # Changes the visibility timeout (i.e. the time before a
      # message that has been received becomes available in the
      # queue again) for a specific message.
      #
      # @request [String] :receipt_handle The receipt handle for the message as returned by the #receive_message action
      # @request [Integer] :visibility_timeout The new timeout value, from 0 to 43200 seconds (12 hours)
      action :change_message_visibility

      # @!method change_message_visibility_batch(request_params)
      # Changes the visibility timeout for up to ten messages at once.
      # Takes one `:messages` parameter which must be an array of
      # hashes; each hash must have the `:id`, `:receipt_handle` and
      # `:visibility_timeout` keys as documented below.
      #
      # @request [Array] :messages Array of hashes specifying new timeout values (max 10):
      # @request [String] :messages[n][:id] A name for this particular timeout change; must be unique within the batch
      # @request [String] :messages[n][:receipt_handle] The receipt handle for the message as returned by the #receive_message action
      # @request [Integer] :messages[n][:visibility_timeout] The new timeout value, from 0 to 43200 seconds (12 hours)
      action :change_message_visibility_batch, filter_params: ->(params){
        messages = params.delete :messages
        1.upto(messages.length) do |index|
          message = messages.shift
          params["ChangeMessageVisibilityBatchRequestEntry.#{index}.Id"] = message[:id]
          params["ChangeMessageVisibilityBatchRequestEntry.#{index}.ReceiptHandle"] = message[:receipt_handle]
          params["ChangeMessageVisibilityBatchRequestEntry.#{index}.VisibilityTimeout"] = message[:visibility_timeout]
        end
      }

      # @!method create_queue(request_params)
      # Creates a new queue with the given name, or simply returns
      # the queue's URL if the named queue already exists. Set
      # attributes with the `:attributes` parameter.
      #
      # @note It's generally simpler to use the SQS.create
      #   class method, which calls this action and returns a
      #   new SQS object pointing to the queue URL.
      #
      # @request [String] :queue_name The queue to be created (maximum 80 character; only alphanumerics, '_', and '-')
      # @request [Hash] :attributes Additional options to set for the queue:
      # @request [Integer] :attributes[:visibility_timeout] The timeout value for received messages, from 0 to 43200 seconds (12 hours); default 30 seconds
      # @request [String] :attributes[:policy] A formal permissions policy for the queue (see SQS Developer Guide)
      # @request [Integer] :attributes[:maximum_message_size] Message limit in bytes, from 1024 to 65536; default 65536 bytes
      # @request [Integer] :attributes[:message_retention_period] Number of seconds a message can be retained in the queue, from 60 (1 minute) to 1209600 (14 days); default 345600 seconds (4 days)
      # @request [Integer] :attributes[:delay_seconds] Time before messages become visible in the queue, from 0 to 900 (15 minutes); default 0 seconds
      #
      # @response [String] :queue_url The URL for the created queue
      action :create_queue

      # @!method delete_message(request_params)
      # Removes a message from the queue after it has been received and
      # processed. The receipt handle from the #receive_message call must
      # be used, *not* the message ID from creation.
      #
      # @request [String] :receipt_handle The receipt handle for the message as returned by the #receive_message action
      action :delete_message

      # @!method delete_message_batch(request_params)
      # Removes up to ten messages from the queue at once.
      # Takes one `:messages` parameter which must be an array of
      # hashes; each hash must have the `:id` and `:receipt_handle`
      # keys as documented below.
      #
      # @request [Array] :messages Array of hashes specifying new timeout values (max 10)
      # @request [String] :messages[n][:id] A name for this particular timeout change; must be unique within the batch
      # @request [String] :messages[n][:receipt_handle] The receipt handle for the message as returned by the #receive_message action
      action :delete_message_batch, filter_params: ->(params){
        messages = params.delete :messages
        1.upto(messages.length) do |index|
          message = messages.shift
          params["DeleteMessageBatchRequestEntry.#{index}.Id"] = message[:id]
          params["DeleteMessageBatchRequestEntry.#{index}.ReceiptHandle"] = message[:receipt_handle]
        end
      }

      # @!method delete_queue
      # Removes the queue at the URL of the request, along with
      # all remaining messages in the queue. Amazon warns that
      # queue deletion may take up to 60 seconds; in that time
      # messages could still be processed, and users should
      # wait that long before recreating a queue with the same name.
      #
      # This method takes no parameters and returns no values.
      action :delete_queue

      # @!method get_queue_attributes(request_params)
      # Returns the requested attributes of the queue.
    end
  end
end
