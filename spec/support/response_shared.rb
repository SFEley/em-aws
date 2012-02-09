shared_examples "an AWS Response" do
  it "knows its header" do
    subject.header.content_type.should == 'text/xml'
  end
  
  it "knows its status" do
    subject.status.should == 200
  end
  
  it "retains the raw XML" do
    subject.xml.should == DummyHttpResponse.new.response
  end
  
end