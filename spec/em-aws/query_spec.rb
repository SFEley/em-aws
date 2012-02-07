require_relative '../spec_helper'


# A subclass independent of any actual Amazon service, so we can mock the requests
class DummyQuery < EventMachine::AWS::Query
  API_VERSION = 'NO-VERSION'
  def service
    'dummy'
  end
end

describe DummyQuery do
  it_behaves_like "an AWS Query"
end