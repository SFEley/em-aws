require_relative '../../spec_helper'

describe EventMachine::AWS::Query::Response do
  # Mock just the things we care about from EM::HttpRequest
  class DummyHttpResponse
    def response_header
      'Response Header'
    end
    def response
      <<-ENDRESPONSE
<DummyActionResponse xmlns="http://dummy.amazonaws.com/doc/2010-03-31/">
  <DummyActionResult>
    <DummyValue>Garbonzo!</DummyValue>
    <Topics>
      <member>
        <TopicArn>arn:aws:sns:us-east-1:429167422711:EM-AWS-Test-Topic</TopicArn>
      </member>
      <member>
        <TopicArn>arn:aws:sns:us-east-1:429167422711:bigthink_alarms</TopicArn>
      </member>
    </Topics>
    <Attributes>
      <entry>
        <key>Foo</key>
        <value>Bar</value>
      </entry>
      <entry>
        <key>SomeNum</key>
        <value>22.5</value>
      </entry>
      <entry>
        <key>SomeTimestamp</key>
        <value>1328734660</value>
      </entry>
    </Attributes>
  </DummyActionResult>
  <ResponseMetadata>
    <RequestId>d6252bf1-5210-11e1-892f-6dd5825e297d</RequestId>
  </ResponseMetadata>
</DummyActionResponse>
ENDRESPONSE
    end
  end
  
  subject {EventMachine::AWS::Query::Response.new DummyHttpResponse.new}
  
  it "knows its header" do
    subject.header.should == 'Response Header'
  end
  
  it "retains the raw XML" do
    subject.xml.should == DummyHttpResponse.new.response
  end
  
  it "tracks its inner attributes" do
    subject[:dummy_value].should == 'Garbonzo!'
  end
  
  it "can make dynamic method calls" do
    subject.dummy_value.should == 'Garbonzo!'
  end
  
  it "handles arrays of members" do
    subject[:topics].should have(2).topics
    subject.topics.first.should == {topic_arn: 'arn:aws:sns:us-east-1:429167422711:EM-AWS-Test-Topic'}
  end
  
  it "handles key/value entry pairs" do
    subject[:attributes].should have(3).keys
    subject.attributes['Foo'].should == 'Bar'
  end
  
  it "knows its action" do
    subject.action.should == 'DummyAction'
  end
  
  it "knows its request ID" do
    subject.request_id.should == 'd6252bf1-5210-11e1-892f-6dd5825e297d'
  end
  
  it "converts to integers appropriately" do
    subject.attributes['SomeTimestamp'].should == 1328734660
  end
  
  it "converts to floats appropriately" do
    subject.attributes['SomeNum'].should == 22.500
  end
  
  
end