require_relative '../spec_helper'

describe EventMachine::AWS::SQS, :live do
  subject {EM::AWS::SQS.new}

  before(:all) do
    queue_name = "EM-AWS-Test-Queue-#{Time.now.to_i}"
    create_response = subject.create_queue(queue_name: queue_name)
    create_response.should be_success
    @queue = create_response.queue_url
  end
  
  it_behaves_like "an AWS Query"

  it "can create a queue" do
    @topic.should =~ /^arn:aws:sns:.*#{@test_topic}$/
  end
  
  it "can retrieve a list of queues" do
    response = subject.list_queues
    response.queues.should include({queue_url: @topic})
  end
  
  after(:all) do
    delete_response = subject.delete_queue(topic_arn: @topic)
    delete_response.should be_success
  end
  

end