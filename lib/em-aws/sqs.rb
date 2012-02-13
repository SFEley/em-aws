require 'em-aws/query'

module EventMachine
  module AWS
    class SQS < Service
      include Query
    end
  end
end