shared_examples "a Service" do
  context "on initializing" do
    def new_subject(*args)
      subject.class.new(*args)
    end
  
    it "knows its endpoint" do
      subject.url.should =~ /^https:.*amazonaws\.com\//
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
      this.url.should =~ /^http:.*eu-west-1/
    end
  
    it "can override the endpoint" do
      this = new_subject(url: 'http://blahblah.org')
      this.url.should == 'http://blahblah.org'
    end  
    
    it "defaults to the global AWS credentials" do
      subject.aws_access_key_id.should == EventMachine::AWS.aws_access_key_id
      subject.aws_secret_access_key.should == EventMachine::AWS.aws_secret_access_key
    end
    
    it "can override the credentials" do
      this = new_subject(aws_access_key_id: "FAKE_OVERRIDE_ACCESS", aws_secret_access_key: "FAKE_OVERRIDE_SECRET")
      this.aws_access_key_id.should == "FAKE_OVERRIDE_ACCESS"
      this.aws_secret_access_key.should == "FAKE_OVERRIDE_SECRET"
    end
    
    it "defaults to POST queries" do
      subject.method.should == :post
    end
    
    it "can override the HTTP method" do
      this = new_subject(method: :get)
      this.method.should == :get
    end
  end
  
  context "making requests", :mock do
    before(:all) do
      @old_retries = EM::AWS.retries
    end
    
    before(:each) do
      @request = EM::AWS::Request.new(subject, :post, foo: 'bar')
      @response = nil
      @request.callback {|r| @response = r; EM.stop}
      @request.errback {|r| @response = r; EM.stop}
    end
    
    context "on network errors", :slow do
      before(:each) do
        stub_request(:post, subject.url).to_timeout.to_timeout.to_timeout.to_return(status: 200, body: 'Success')
      end
      
      it "retries on HTTP request failure" do
        EM.run {subject.send(:send_request, @request)}
        @response.body.should == 'Success'
        @request.attempts.should == 4
      end
    
      it "fails out if the retry limit is exceeded" do
        EM::AWS.retries = 2
        EM.run {subject.send(:send_request, @request)}
        @response.should be_a(EM::AWS::FailureResponse)
        @request.attempts.should == 3
      end
      
      it "delays based on Fibonacci sequence" do
        start_time = Time.now
        EM.run {subject.send(:send_request, @request)}
        (Time.now - start_time).should be_within(0.1).of(4)
      end
    end
    
    context "on Amazon 500 errors" do
      before(:each) do
        stub_request(:post, subject.url).to_return(status: 500).to_return(status: 503).to_return(status: 502).to_return(status: 200, body: 'Success')
      end
      
      it "retries until success" do
        EM.run {subject.send(:send_request, @request)}
        @response.body.should == 'Success'
        @request.attempts.should == 4
      end

      it "fails out if the retry limit is exceeded" do
        EM::AWS.retries = 2
        EM.run {subject.send(:send_request, @request)}
        @response.should be_a(EM::AWS::Query::QueryFailure)
        @request.attempts.should == 3
      end

      it "delays based on Fibonacci sequence" do
        start_time = Time.now
        EM.run {subject.send(:send_request, @request)}
        (Time.now - start_time).should be_within(0.1).of(4)
      end
    end
    
    after(:each) do
      EM::AWS.retries = @old_retries
    end
  end
  

end