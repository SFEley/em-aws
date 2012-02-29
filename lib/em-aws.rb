require "eventmachine"
require "em-aws/version"
require "em-aws/service"
require "em-aws/logger"


module EventMachine
  
  # The AWS module (besides containing everything else) has module attributes that set
  # default credentials and behavior for every interface.
  module AWS
    extend Logger
    
    # Default values
    @region = 'us-east-1'
    @ssl = true
    @retries = 10
    
    # Global configuration (trickles down to all query classes)
    class << self
      
      # (Must be set in class initializers if you don't set it here)
    	attr_accessor :aws_access_key_id, :aws_secret_access_key
    	
    	# Defaults to **'us-east-1'**
    	attr_accessor :region
    	
    	# Defaults to **true**
    	attr_accessor :ssl
    	
    	# Defaults to **10**; applies to network errors and Amazon 50x errors
    	attr_accessor :retries
    end

    # Don't load any services we don't need
    autoload :SNS, 'em-aws/sns'
    autoload :SQS, 'em-aws/sqs'
    
    class Error < StandardError; end

  end
end
