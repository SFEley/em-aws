require "eventmachine"
require "em-aws/version"
require "em-aws/query"


module EventMachine
  module AWS
    
    # Default values
    @region = 'us-east-1'
    @ssl = true
    @retries = 10
    
    # Global configuration (trickles down to all query classes)
    class << self
    	attr_accessor :aws_access_key_id, :aws_secret_access_key, :region, :ssl, :retries
    end

    # Don't load any services we don't need
    autoload :SNS, 'em-aws/sns'
    autoload :SQS, 'em-aws/sqs'

  end
end
