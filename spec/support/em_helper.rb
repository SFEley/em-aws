require "eventmachine"
module EventMachineHelper

  # Wrap the given code in an EM.run and EM.stop block
  def event
    EM.run do
      yield
      EM.stop
    end
  end

  # Log everything that goes through EM::HTTP::Request
  class Logger
    def request(c, h, b)
      p [c,h,b]
      [h,b]
    end
  end
  
  EM::HttpRequest.use Logger if ENV['AWS_LOGGING'] == 'true' 
  
end