require 'ostruct'

# # Mock just the things we care about from EM::HttpRequest
class DummyHttpResponse
  def response_header
    @rh ||= OpenStruct.new "status" => 200, "content_type" => "text/xml"
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
