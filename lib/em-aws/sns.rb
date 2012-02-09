require 'em-aws/query'

module EventMachine
  module AWS
    class SNS < Service
      include Query
      
      API_VERSION = '2010-03-31'
    end
  end
end