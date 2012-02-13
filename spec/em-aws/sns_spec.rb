require_relative '../spec_helper'

describe EventMachine::AWS::SNS, :live do
  subject {EM::AWS::SNS.new}

  before(:all) do
    topic_name = "EM-AWS-Test-Topic-#{Time.now.to_i}"
    create_response = subject.create_topic(name: topic_name)
    create_response.should be_success
    @topic = create_response.topic_arn
  end
  
  it_behaves_like "an AWS Query"

  it "can create a topic" do
    @topic.should =~ /^arn:aws:sns:.*#{@test_topic}$/
  end
  
  it "can retrieve a list of topics" do
    response = subject.list_topics
    response.topics.should include({topic_arn: @topic})
  end
  
  after(:all) do
    delete_response = subject.delete_topic(topic_arn: @topic)
    delete_response.should be_success
  end
  

end