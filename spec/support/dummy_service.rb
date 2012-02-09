# A subclass independent of any actual Amazon service, so we can mock the requests
class DummyQuery < EventMachine::AWS::Query
  API_VERSION = 'NO-VERSION'
  def service
    'dummy'
  end
end

