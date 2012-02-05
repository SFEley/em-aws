require_relative 'spec_helper'

describe EventMachine::AWS do
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

end

