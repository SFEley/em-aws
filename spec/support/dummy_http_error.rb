require 'ostruct'

# # Mock just the things we care about from EM::HttpRequest
class DummyHttpError
  def error
  end
  def response_header
    @rh ||= OpenStruct.new "status" => 400, "content_type" => "text/xml"
  end
  def response
    <<-ENDRESPONSE
<ErrorResponse xmlns="http://dummy.amazonaws.com/doc/NO-VERSION/">
  <Error>
    <Type>Sender</Type>
    <Code>DummyFailure</Code>
    <Message>This is a test failure.</Message>
  </Error>
  <RequestId>f75889c3-520e-11e1-9f63-79e70d4e1f28</RequestId>
</ErrorResponse>
ENDRESPONSE
  end
end
