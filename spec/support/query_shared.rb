shared_examples "an AWS Query" do
  
  before(:all) do
    subject.class.instance_eval 'action :dummy_action'
  end
  
  it_behaves_like "a Service"
  
  context "making requests", :mock do
    before(:each) do
      @url = %r[#{subject.url}.*]
      @time = Time.at(1310243403)  # About 4:30 PM EDT on July 9, 2011
      Time.stub!(:now).and_return(@time)
      stub_request(:post, @url)
    end
    
    it "queries the server" do
      event {subject.call(:DummyAction)}
      WebMock.should have_requested(:post, @url)        
    end
    
    it "adds a version" do
      event {subject.call :dummy_action}
      WebMock.should have_requested(:post, @url).with(body: hash_including('Version' => subject.class::API_VERSION))
    end
    
    it "adds a timestamp if there was none" do
      event {subject.call :dummy_action}
      WebMock.should have_requested(:post, @url).with(body: hash_including('Timestamp' => '2011-07-09T20:30:03Z'))
    end
    
    it "keeps the timestamp intact if there was one" do
      event {subject.call :dummy_action, timestamp: '2012-02-06T19:33:33Z'}
      WebMock.should have_requested(:post, @url).with(body: hash_including('Timestamp' => '2012-02-06T19:33:33Z'))
    end
      
    it "also passes any parameters" do
      event {subject.call :DummyAction, ThisThing: 'is cool!'}
      WebMock.should have_requested(:post, subject.url).with(body: hash_including({
        'ThisThing' => 'is cool!', 
        'Action' => 'DummyAction'}))
    end
    
    it "fixes the capitalization on Ruby-style actions and symbols" do
      event {subject.call :dummy_action, this_thing: 'is cool!'}
      WebMock.should have_requested(:post, subject.url).with(body: hash_including({
        'ThisThing' => 'is cool!', 
        'Action' => 'DummyAction'}))
    end      
    
    it "doesn't sign if no access key was given" do
      @original_access_key = EM::AWS.aws_access_key_id
      EM::AWS.aws_access_key_id = nil
      this = subject.class.new
      event {this.call :dummy_action}
      WebMock.should_not have_requested(:post, @url).with(body: hash_including({
        'SignatureVersion' => '2'
      }))
      EM::AWS.aws_access_key_id = @original_access_key
    end

    it "doesn't sign if no secret key was given" do
      @original_secret_key = EM::AWS.aws_secret_access_key
      EM::AWS.aws_secret_access_key = nil
      this = subject.class.new
      event {this.call :dummy_action}
      WebMock.should_not have_requested(:post, @url).with(body: hash_including({
        'SignatureVersion' => '2'
      }))
      EM::AWS.aws_secret_access_key = @original_secret_key
    end
      
    it "signs the request if an access key is available" do
      event {subject.call(:dummy_action)}
      WebMock.should have_requested(:post, subject.url).with(body: hash_including({
        'SignatureVersion' => '2',
        'SignatureMethod' => 'HmacSHA256',
        'AWSAccessKeyId' => 'FAKE_KEY'}))
    end
    
    it "handles GET requests too" do
      stub_request :get, @url
      this = subject.class.new method: :get
      event {this.call :dummy_action, some_param: 'foo'}
      WebMock.should have_requested(:get, subject.url).with(query: hash_including({
        'Action' => 'DummyAction',
        'SomeParam' => 'foo',
        'AWSAccessKeyId' => 'FAKE_KEY'
      }))
    end
    
    it "supports dynamic method calls" do
      event {subject.dummy_action this_thing: "is dynamic!"}
      WebMock.should have_requested(:post, subject.url).with(body: hash_including({
        'ThisThing' => 'is dynamic!', 
        'Action' => 'DummyAction'}))
    end
    
    it "is synchronous if EM isn't running" do
      subject.dummy_action now_this: "is synchronous!"
      WebMock.should have_requested(:post, subject.url).with(body: hash_including({
        'NowThis' => 'is synchronous!', 
        'Action' => 'DummyAction'}))
    end
    
    it "splits hashes into Attribute.n.Name and Attribute.n.Value pairs" do
      subject.dummy_action attribute: {foo: 'bar', some_number: 12.3}
      WebMock.should have_requested(:post, subject.url).with(body: hash_including({
        'Attribute.1.Name' => 'Foo',
        'Attribute.2.Name' => 'SomeNumber',
        'Attribute.1.Value' => 'bar',
        'Attribute.2.Value' => '12.3'
      }))
    end
      
  end
  
  context "handling responses", :mock do
    before(:each) do
      stub_request(:post, subject.url).to_return(status: 200, body: '<DummyActionResponse xmlns="http://example.org/2012-02-07/"><DummyActionResult><AnswerOne>foo</AnswerOne><AnswerTwo>17</AnswerTwo></DummyActionResult><ResponseMetadata><RequestId>a8dec82-89298b-83cef-9123-389aa</RequestId></ResponseMetadata></DummyActionResponse>')
      @response = nil
    end
    
    it "takes a block for a callback" do
      event do
        subject.call :dummy_action do |resp|
          @response = resp
        end
      end
      @response.should be_an(EM::AWS::Response)
      @response.answer_one.should == 'foo'
    end
    
    it "returns the request when called within EventMachine" do
      litmus = nil
      event {litmus = subject.dummy_action}
      litmus.should be_an(EM::AWS::Request)
      litmus.response.answer_one.should == 'foo'
    end
    
    it "returns the request when called synchronously" do
      litmus = subject.dummy_action zoo: 'zar'
      litmus.should be_an(EM::AWS::Request)
      litmus['AnswerTwo'].should == 17
    end
    
    it "raises an exception when called synchronously" do
      stub_request(:post, subject.url).to_return(status: 400, body: DummyHttpError.new.response)
      ->{subject.dummy_action floo: 'flar'}.should raise_error(EM::AWS::Query::QueryError, /DummyFailure/)
    end
  end

end