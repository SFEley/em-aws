require_relative '../../spec_helper'

describe EventMachine::AWS::Query::QueryFailure do
  before(:each) do
    @response = DummyHttpError.new
  end
  
  subject {EventMachine::AWS::Query::QueryFailure.new @response}
  
  it_behaves_like "an AWS Response"
  
  it "knows its request ID" do
    puts subject.metadata
    subject.request_id.should == 'f75889c3-520e-11e1-9f63-79e70d4e1f28'
  end
  
  it "knows its error type" do
    subject.type.should == 'Sender'
  end
  
  it "knows its error code" do
    subject.code.should == 'DummyFailure'
  end
  
  it "knows its error message" do
    subject.message.should == 'This is a test failure.'
  end
  
  it "throws an exception when attempting to access any attributes" do
    -> {subject[:foo]}.should raise_error(EventMachine::AWS::Query::QueryError, /DummyFailure/)
  end

  it "throws an exception when calling dynamic methods" do
    -> {subject.foo}.should raise_error(EventMachine::AWS::Query::QueryError, /DummyFailure/)
  end
  
end