shared_examples "an AWS Query" do
  def new_subject(*args)
    subject.class.new(*args)
  end
  
  it "knows its endpoint" do
    subject.endpoint.should =~ /^https:.*amazonaws\.com\/$/
  end
  
  it "defaults to the global region" do
    subject.region.should == 'us-east-1'
  end
  
  it "can override the region" do
    new_subject(region: 'ap-southeast-1').region.should == 'ap-southeast-1'
  end
  
  it "defaults to the global SSL setting" do
    subject.ssl.should == true
  end
  
  it "can override the SSL setting" do
    new_subject(ssl: false).ssl.should be_false
  end
  
  it "computes the endpoint from the provided region and SSL settings" do
    this = new_subject(ssl: false, region: 'eu-west-1')
    this.endpoint.should =~ /^http:/
    if subject.endpoint =~ /us-east-1/
      this.endpoint.should =~ /eu-west-1/
    end
  end
  
  it "can override the endpoint" do
    this = new_subject(endpoint: 'http://blahblah.org')
    this.endpoint.should == 'http://blahblah.org'
  end
  
end