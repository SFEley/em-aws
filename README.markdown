# EventMachine::AWS #

**EM::AWS** is a thin Ruby wrapper for making calls to Amazon Web Services.  It transparently signs requests, automatically retries on server errors, and unwraps XML responses into simple attributes. Unlike most other AWS libraries, it _does not_ provide an object model for any of Amazon's services. It simply makes API calls and exposes the responses. Other gems or applications can build on this generic foundation to construct whatever higher-level model is appropriate for their needs.

It also differs from other EventMachine libraries by offering a fully synchronous mode that _does not require_ EventMachine to be running. (The method call simply starts and stops EM behind the scenes.) This mode is less efficient but makes it easier to use **EM::AWS** in non-evented frameworks such as Rails.

At this stage in its development, **EM::AWS** supports the Amazon Query Protocol. This is the GET- or POST-based API framework used for virtually every Amazon service _except S3._  Support for S3's idiosyncratic REST API will likely come in a future release.

## Getting Started ##

The **em-aws** gem is dependent on the **eventmachine**, **em-http-request**, and **nokogiri** gems.  It was built and tested with Ruby 1.9, but should work with Rubinius and JRuby in 1.9 compatibility mode.  _It will not work in Ruby 1.8._

Once you've added it to your Gemfile (or run `gem install em-aws`) you can supply the usual authentication credentials somewhere in your application's initialization:

    require 'em-aws'
    
    EM::AWS.aws_access_key_id = 'YOUR_ACCESS_KEY'
    EM::AWS.aws_secret_access_key = 'YOUR_SECRET_KEY'
    
    # These global defaults can also be tweaked:
    # EM::AWS.region = 'us-east-1'
    # EM::AWS.ssl = true
    # EM::AWS.retries = 10
    
If you don't want to supply your credentials globally, or need to use multiple identities in the same application, you can pass any of the above as options when constructing individual service objects:

    # Easiest way to hook to Simple Notification Service:
    sns = EM::AWS::SNS.new
    
    # The tricked-out version:
    sns2 = EM::AWS::SNS.new aws_access_key_id: 'OTHER_ACCESS_KEY',
                            aws_secret_access_key: 'OTHER_SECRET_KEY',
                            region: 'ap-southeast-1',
                            ssl: false,
                            method: :get

## Queries Without EventMachine ##

If the EventMachine reactor is not running, **EM::AWS** defaults to a simple synchronous mode.  API calls are dynamic methods, and calling one returns a response object which makes its values available as a hash or attributes:

    sns = EM::AWS::SNS.new
    
    response = sns.create_topic name: 'MyTestTopic'   # 'CreateTopic' API call
    response.success?     #=> true
    response.topic_arn    #=> arn:aws:sns:us-east-1:123456789012:MyTestTopic
    response[:topic_arn]  #=> (same; the 'TopicArn' response value)

Note that in both requests and responses, Amazon's CamelCase strings (`"SomeParameter"`) are converted into snake_case symbols (`:some_parameter`) per Ruby idiom.

**EM::AWS** makes no attempt to validate your queries nor their parameters. If you attempt to call a method that does not exist, or supply bad values, it is up to Amazon itself to return an error.  In synchronous mode, any errors (other than 500 "internal server" errors, which are retried) are raised as **EM::AWS::Error** exceptions or some subclass thereof.

## Queries With EventMachine ##

In an evented **EM.run** loop, query calls are similar to the above.  The main difference is that a _request_ object is returned rather than the _response_ object. The request object includes the Deferrable module, and `callback` and `errback` blocks can be attached to it to process the response.  

As a shortcut, the query itself can be passed a block, which becomes the first `callback`:

    EM.run do
      sns = EM::AWS::SNS.new
      
      request = sns.create_topic name: 'MyTestTopic' do |response|
        puts response.topic_arn
      end
      
      # Other blocks can be chained to the request:
      
      request.callback do |response|
        sns.get_topic_attributes(topic_arn: response.topic_arn) do |resp2|
          # ...other processing here...
          EM.stop
        end
      end
      
      # Don't forget to handle failure cases:
      
      request.errback do |response|
        puts "FAILURE: #{response.error}"
        EM.stop
      end
    end
    
All request blocks are passed a **Response** object.  If the query succeeded (i.e. came back with HTTP status 200), the `callback` blocks are called.  The response object is a subclass of **SuccessResponse** and makes the values returned from Amazon available as attributes.  

If the query failed (usually with a status in the 400s), the `errback` blocks are called.  The response is a subclass of **FailureResponse** and contains the error `:code` and `:message` returned by Amazon.  Attempting to reference other attributes raises an exception with the same information. 
                            
## General Notes ##

The following behavior is true for all AWS services:

* **EM::AWS** uses HTTP POST by default for all Query Protocol calls. It is possible to override this by passing `method: :get` on service object initialization, but this will limit the amount of data that can be passed.
* SSL is enabled by default. You can disable it globally with `EM::AWS.ssl = false` or locally by passing `ssl: false` on service object initialization.
* XML response values that include lists of `<member>` elements will be flattened into arrays.
* XML response values that include `<key>` and `<value>` pairs will be flattened into Ruby hashes.
* Network errors and Amazon HTTP 500 errors are automatically retried; the number of attempts can be set with the `EM::AWS.retries` attribute. (The default is 10.) 
* The retry delay follows a Fibonacci sequence: the first two retries are 1 second apart, then 2 seconds, then 3, then 5, etc.  A full cycle of 10 retries thus takes 143 seconds. If the error is not resolved by that time, it will be returned as a **FailureResponse**.
* If any query receives a `Throttling` response from Amazon, it will also be retried, and subsequent calls to the same service will be subject to a 1 second delay.  The delay will expire if two minutes pass without a throttling error.

## SQS ##

The Simple Queue Service behaves differently from most other Amazon services, in that most calls must be made to a _queue URL_ rather than a root path.  This must be supplied on initialization of the **EM::AWS::SQS** object.  If you already know the URL of the queue you want to work with, you can simply pass it with the `:url` parameter:

    queue = EM::AWS::SQS.new url: 'https://sqs.us-east-1.amazonaws.com/1234567890/My-Interesting-Queue'
    
If you know a queue's name but not its URL, you can use the `.get` class method to call 'GetQueueUrl' and create the proper SQS object:

    queue = EM::AWS::SQS.get 'My-Interesting-Queue'
    
You can also create a queue that doesn't exist yet using the `.create` class method, passing any optional attributes as a hash:

    queue = EM::AWS::SQS.create 'My-Interesting-Queue', 
        visibility_timeout: 120,
        maximum_message_size: 8192

(If a queue with that name already exists, the `.create` class method has the same net effect as `.get`, except that Amazon will return an error if you pass any attributes that are different from the ones already set.)


      

    
    