require 'em-aws/query'

# A subclass independent of any actual Amazon service, so we can mock the requests
class DummyQuery < EventMachine::AWS::Service
  include EventMachine::AWS::Query
  
  API_VERSION = 'NO-VERSION'
  def service
    'dummy'
  end
  
  action :dummy_action
  
end

