#encoding: UTF-8

require_relative '../../spec_helper'

describe EventMachine::AWS::Query::SignatureV2 do
  subject {EventMachine::AWS::Query::SignatureV2.new 'FAKE_KEY', 'FAKE_SECRET', :post, "http://dummy.us-east-1.amazonwebservices.com/some_path/"}
  
  before(:each) do
    @params = {
      'Zoo' => 'Animal lives here',
      'Bank' => 11.5,
      'BEEBLE' => 'brox',
      'Viel' => "Spaß"
    }
  end
  
  it "creates a signable string" do
    subject.signable_params(@params).should == 'POST
dummy.us-east-1.amazonwebservices.com
/some_path/
BEEBLE=brox&Bank=11.5&Viel=Spa%C3%9F&Zoo=Animal+lives+here'
  end
  
  it "signs what it's given with the secret key" do
    subject.hmac_sign('This is just a test string').should == 'HCyF++QVmIQX3ejga93OG/OzBGIVDJ5jZqFy6vlGfzU='
  end
  
  it "returns the signature params" do
    subject.signature(@params).should == {
      AWSAccessKeyId: 'FAKE_KEY',
      SignatureMethod: 'HmacSHA256',
      SignatureVersion: 2,
      Signature: 'hWshnlmzWyvHhZ3b5Jg+mwHnkDWd/StmXod/Xc8+9B0='
    }
  end
  
end

