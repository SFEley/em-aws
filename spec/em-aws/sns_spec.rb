require_relative '../spec_helper'

describe EventMachine::AWS::SNS do
  subject {EM::AWS::SNS.new}

  # it_behaves_like "an AWS Query"
  
  describe "AddPermission", :mock do
    before(:each) do
      @arn = 'arn:aws:sns:us-east-1:429167422711:EM-AWS-Test-Topic'
      @label = 'TestPolicy'
      stub_request(:post, subject.url)
    end
    
    it "can take a single account ID and action" do
      subject.add_permission topic_arn: @arn, label: @label, aws_account_id: 123456789012, action_name: :delete_topic
      WebMock.should have_requested(:post, subject.url).with(body: hash_including({
        'AWSAccountId.member.1' => '123456789012',
        'ActionName.member.1' => 'DeleteTopic',
        'TopicArn' => @arn,
        'Label' => @label
      }))
      
    end

    it "can take arrays of account IDs and actions" do
      subject.add_permission topic_arn: @arn, label: @label, 
          aws_account_id: [123456789012, 123456789012, 109876543210], 
          action_name: [:subscribe, :get_topic_attributes, :subscribe]
      WebMock.should have_requested(:post, subject.url).with(body: hash_including({
        'AWSAccountId.member.1' => '123456789012',
        'ActionName.member.1' => 'Subscribe',
        'AWSAccountId.member.2' => '123456789012',
        'ActionName.member.2' => 'GetTopicAttributes',
        'AWSAccountId.member.3' => '109876543210',
        'ActionName.member.3' => 'Subscribe',
        'TopicArn' => @arn,
        'Label' => @label
      }))
      
    end
    
    it "can take a permissions hash" do
      subject.add_permission topic_arn: @arn, label: @label, 
          permissions: {
            123456789012 => [:subscribe, :get_topic_attributes],
            109876543210 => :subscribe
          }
      WebMock.should have_requested(:post, subject.url).with(body: hash_including({
        'AWSAccountId.member.1' => '123456789012',
        'ActionName.member.1' => 'Subscribe',
        'AWSAccountId.member.2' => '123456789012',
        'ActionName.member.2' => 'GetTopicAttributes',
        'AWSAccountId.member.3' => '109876543210',
        'ActionName.member.3' => 'Subscribe',
        'TopicArn' => @arn,
        'Label' => @label
      }))
      
    end
    
    it "can mix arrays and the permissions hash" do
      subject.add_permission topic_arn: @arn, label: @label, 
          permissions: {
            123456789012 => [:subscribe, :get_topic_attributes],
            109876543210 => :subscribe
          },
          aws_account_id: [109876543210, 109876543210], 
          action_name: [:delete_topic, :confirm_subscription]
          
      WebMock.should have_requested(:post, subject.url).with(body: hash_including({
        'AWSAccountId.member.1' => '109876543210',
        'ActionName.member.1' => 'DeleteTopic',
        'AWSAccountId.member.2' => '109876543210',
        'ActionName.member.2' => 'ConfirmSubscription',
        'AWSAccountId.member.3' => '123456789012',
        'ActionName.member.3' => 'Subscribe',
        'AWSAccountId.member.4' => '123456789012',
        'ActionName.member.4' => 'GetTopicAttributes',
        'AWSAccountId.member.5' => '109876543210',
        'ActionName.member.5' => 'Subscribe',
        'TopicArn' => @arn,
        'Label' => @label
      }))
    end
  end

  context "live requests", :live do
    before(:all) do
      topic_name = "EM-AWS-Test-Topic-#{Time.now.to_i}"
      create_response = subject.create_topic(name: topic_name)
      create_response.should be_success
      @topic = create_response.topic_arn
    end
  

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
  

end