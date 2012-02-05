require_relative '../spec_helper'

describe EventMachine::AWS::SNS do
  before do
    @test_topic = "EM-AWS-Test-Topic-#{Time.now.to_i}"
  end
  
  subject {EM::AWS::SNS.new}
  
  it_behaves_like "an AWS Query"

  it "can create a topic" do
    done = false
    subject.create_topic(name: @test_topic) do |response|
      response['TopicArn'].should =~ /^arn:aws:sns:.*#{@test_topic}$/
      done = true
    end

    sleep 1 until done;
  end

end