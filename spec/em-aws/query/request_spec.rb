require_relative '../../spec_helper'

describe EventMachine::AWS::Query::Request do
  subject {EM::AWS::Query::Request.new DummyQuery.new, 'Action' => 'DummyAction', 'SomeParam' => 5}
  
  it "knows its service" do
    subject.service.should be_a(DummyQuery)
  end
  
  it "knows its parameters" do
    subject['SomeParam'].should == 5
  end
  
  it "is indifferent to its parameter form" do
    subject[:some_param].should == 5
  end
  
  it "knows how many delivery tries it's had" do
    subject.attempts.should == 0
  end
  
  it "doesn't have a response when it's new" do
    subject.response.should be_nil
  end
  
  it {should_not be_finished}
  
  it {should_not be_success}
    
  
  context "on successful response" do
    before(:each) do
      @response = EventMachine::AWS::Query::SuccessResponse.new DummyHttpResponse.new
      event {subject.succeed @response}
    end
    
    it {should be_finished}
    
    it {should be_success}
    
    it "knows its response" do
      subject.response.should == @response
    end
  end
  
  context "on failed response" do
    
  end
end