require_relative '../spec_helper'

describe EventMachine::AWS::SQS do

  before(:all) do
    @queue_name = "EM-AWS-Test-Queue-#{Time.now.to_i}"
  end

  it_behaves_like "an AWS Query"
  
  it "derives the queue name from the URL" do
    this = EM::AWS::SQS::new url: 'http://dummy.amazonaws.com/fake-queue-name'
    this.queue_name.should == 'fake-queue-name'
  end

  context "operations", :live do
    before(:all) do
      @queue = EM::AWS::SQS.create @queue_name
      sleep 60
    end
    
    subject { @queue }
    
    it "points to the proper queue" do
      subject.url.should =~ /http.*\/#{@queue_name}$/
    end
    
    it "can retrieve a list of queues" do
      response = subject.list_queues
      response.queue_url.should include(subject.url)
    end
    
    it "can get the queue by name" do
      queue = EM::AWS::SQS.get @queue_name
      queue.url.should == subject.url
    end
    
    it "can set attributes on the queue" do
      subject.set_queue_attributes attribute: {maximum_message_size: 1024}
      sleep 10
      response = subject.get_queue_attributes attribute_name: [:maximum_message_size]
      response.attribute[:maximum_message_size].should == 1024
    end
      
    
    after(:all) do
      sleep 10
      delete_response = subject.delete_queue
      delete_response.should be_success
    end
  end

end