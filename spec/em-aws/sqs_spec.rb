require_relative '../spec_helper'

describe EventMachine::AWS::SQS do

  it_behaves_like "an AWS Query"


  let(:queue_name) {"EM-AWS-Test-Queue-#{Time.now.to_i}"}

  it "derives the queue name from the URL" do
    this = EM::AWS::SQS::new url: 'http://dummy.amazonaws.com/fake-queue-name'
    this.queue_name.should == 'fake-queue-name'
  end

  context "global endpoint actions", :live do
    it "can :create_queue" do
      subject.create_queue(queue_name).should be_success

    end
  end



  context "operations", :live do
    pending
    before(:all) do
      @queue = EM::AWS::SQS.create @queue_name, visibility_timeout: 67
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

    it "can set attributes on queue creation" do
      response = subject.get_queue_attributes attribute_name: ['All']
      response.visibility_timeout.should == 67
    end

    it "can set attributes on the queue" do
      subject.set_queue_attributes attribute: {maximum_message_size: 1024}
      sleep 20
      response = subject.get_queue_attributes attribute_name: ['MaximumMessageSize']
      response.maximum_message_size.should == 1024
    end

    it "can publish and process a message to the queue" do
      message = "Now is the time for all good men
      to come to the aid of their party!"
      subject.send_message message_body: message
      sleep 10
      response = subject.receive_message
      response.message[:body].should == message
      delete_response = subject.delete_message receipt_handle: response.message[:receipt_handle]
      delete_response.should be_success
    end


    after(:all) do
      sleep 10
      delete_response = subject.delete_queue
      delete_response.should be_success
    end
  end

end
