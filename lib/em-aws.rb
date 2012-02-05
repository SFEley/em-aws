require "eventmachine"
require "em-aws/version"
require "em-aws/query"


module EventMachine
  module AWS
    
    # Global configuration (trickles down to all submodules)
    class << self
    	attr_accessor :aws_access_key_id, :aws_secret_access_key
    	attr_writer   :region, :ssl
    	
    	def region
    	  @region ||= 'us-east-1'
  	  end
  	  
  	  def ssl
  	    @ssl ||= true
	    end
    end

    # Don't load any services we don't need
    autoload :SNS, 'em-aws/sns'
    autoload :SQS, 'em-aws/sqs'

  end
end
