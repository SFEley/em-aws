require_relative 'spec_helper'

describe EventMachine::AWS do
  before(:each) do
    @original_access_key = EventMachine::AWS.aws_access_key_id
    @original_secret_key = EventMachine::AWS.aws_secret_access_key
  end
  
  it "lets you specify a global Access Key" do
    EventMachine::AWS.aws_access_key_id = 'BlahBlah'
    EventMachine::AWS.aws_access_key_id.should == 'BlahBlah'
  end

  it "lets you specify a global Secret Key" do
    EventMachine::AWS.aws_secret_access_key = 'BlahBlah'
    EventMachine::AWS.aws_secret_access_key.should == 'BlahBlah'
  end
  
  it "defaults the region to us-east-1" do
    EventMachine::AWS.region.should == 'us-east-1'
  end
  
  it "defaults to SSL being true" do
    EventMachine::AWS.ssl.should == true
  end
  
  it "retries 10 times by default" do
    EventMachine::AWS.retries.should == 10
  end

  after(:each) do
    EventMachine::AWS.aws_access_key_id = @original_access_key
    EventMachine::AWS.aws_secret_access_key = @original_secret_key
  end
    
end

