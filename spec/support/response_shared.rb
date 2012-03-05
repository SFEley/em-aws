shared_examples "an AWS Response" do

  it "knows its header" do
    subject.header.content_type.should == 'text/xml'
  end
  
  it "knows its status" do
    subject.status.should == @response.response_header.status
  end
  
  it "retains the raw result" do
    subject.body.should == @response.response
  end
  
end