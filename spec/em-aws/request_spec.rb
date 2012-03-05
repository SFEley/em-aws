require_relative '../spec_helper'

describe EventMachine::AWS::Request do
  subject {EM::AWS::Request.new DummyQuery.new, :get, 'Action' => 'DummyAction', 'SomeParam' => 5}
  
  it "knows its service" do
    subject.service.should be_a(DummyQuery)
  end
  
  it "knows its method" do
    subject.method.should == :get
  end
  
  it "knows its parameters" do
    subject.params['SomeParam'].should == 5
  end
  
  it "knows how many delivery tries it's had" do
    subject.attempts.should == 0
  end
  
  it "doesn't have a response when it's new" do
    subject.response.should be_nil
  end
  
  it "doesn't have a status when it's new" do
    subject.status.should be_nil
  end
  
  it "throws a method missing error on data access attempts" do
    ->{subject.dummy_value}.should raise_error(NoMethodError)
  end
  
  it "throws a method missing error on hash access attempts" do
    ->{subject[:dummy_value]}.should raise_error(NoMethodError)
  end
  
  
  it {should_not be_finished}
  
  it {should_not be_success}
    
  
  context "on successful response" do
    before(:each) do
      @response = EventMachine::AWS::Query::QueryResult.new DummyHttpResponse.new
      event {subject.succeed @response}
    end
    
    it {should be_finished}
    
    it {should be_success}
    
    it "knows its response" do
      subject.response.should == @response
    end
    
    it "makes the response data available as a hash" do
      subject[:dummy_value].should == 'Garbonzo!'
    end
    
    it "makes the response data available as attributes" do
      subject.dummy_value.should == 'Garbonzo!'
    end
    
    it "knows its status after completion" do
      subject.status.should == 200
    end
    
    it "invokes any callback routines" do
      litmus = nil
      event {subject.callback {|r| litmus = r}}
      litmus.dummy_value.should == 'Garbonzo!'
    end
  end
  
  context "on failed response" do
    before(:each) do
      @response = EventMachine::AWS::Query::QueryFailure.new DummyHttpError.new
      event {subject.fail @response}
    end
    
    it {should be_finished}
    
    it {should_not be_success}
    
    it "knows its response" do
      subject.response.should == @response
    end
    
    it "knows its error from the response" do
      subject.error.should == 'DummyFailure'
    end
    
    it "throws an exception on data access" do
      ->{subject.dummy_value}.should raise_error(EM::AWS::Query::QueryError)
    end
    
    it "invokes any errback routines" do
      litmus = nil
      event {subject.errback {|r| litmus = r}}
      litmus.code.should == 'DummyFailure'
    end
    
  end
end