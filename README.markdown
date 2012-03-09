# EventMachine::AWS #

**EM::AWS** is a thin Ruby wrapper for making calls to [Amazon Web Services][AWS].  It transparently signs requests, automatically retries on server errors, and unwraps XML responses into simple attributes. Unlike most other AWS libraries, it _does not_ provide an object model for any of Amazon's services. It simply makes API calls and exposes the responses. Other gems or applications can build on this generic foundation to construct whatever higher-level model is appropriate for their needs.

It also differs from other [EventMachine][EM] libraries by offering a fully synchronous mode that _does not require_ EventMachine to be running. (The query call simply starts and stops EM behind the scenes.) This mode is less efficient but makes it easier to use **EM::AWS** in non-evented frameworks such as Rails.

At this stage in its development, **EM::AWS** supports the Amazon Query Protocol for the following services:

* [**SNS** - Simple Notification Service][SNS]
* [**SQS** - Simple Query Service][SQS]

Other services will be added shortly, _except S3._  Support for S3's idiosyncratic REST API will likely come in a future release.

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

## Making Queries ##

To make any AWS request, simply create a service object of the appropriate class and then call the API action as a method using Ruby *snake_case* conventions.  Pass parameters as a hash:

    sns = EM::AWS::SNS.new
    request = sns.create_topic name: 'MyTestTopic'
    
The request object also receives and parses the response, and makes the returned values available as attributes or a hash:

    request.finished?    #=> true
    request.status       #=> 200
    request.topic_arn    #=> arn:aws:sns:us-east-1:123456789012:MyTestTopic
    request[:topic_arn]  #=> (same)
    request['TopicArn']  #=> (same)

The request can be passed a block, which -- if the request is successful -- receives the parsed response data and can act on it any way you like (in EventMachine terms, it becomes a _callback_):

    # Subscribe to the topic once created
    sns.create_topic name: 'MyTestTopic' do |response|
      sns.subscribe protocol: 'email', endpoint: 'myself@example.org',
                    topic_arn: response.topic_arn do |resp2|
        puts "Subscribed to topic #{response.topic_arn}."
        puts "Your subscription ID is #{resp2.subscription_arn}."
        puts "Check your email!"
      end
    end
    
This single block usage works in both EventMachine and synchronous modes. (See below.)  If you want to add more than one callback, or handle query failures in a similar way, you'll need to use EventMachine callbacks and errbacks.

## Queries With EventMachine ##

In an evented `EM.run` loop, calling any query method will return the request object immediately.  The `#finished?` attribute on the request will initially be _false_. The HTTP request will be made and the response received and parsed within the [EventMachine][EM] loop, after which `#finished?` will be _true_.  The `#success?` attribute will then be _true_ if Amazon returned a successful response, or _false_ if an error was received from Amazon.

The **Request** object mixes in the [**EventMachine::Deferrable**][DEFER] module, meaning you can attach blocks using the `#callback` and `#errback` methods.  This is the primary means for evented programming with this gem.  

(**Note:** Unless your entire program runs a continuous EventMachine loop, remember to call `EM.stop` when you're finished handling all requests. You will need to do so for both success and failure cases.)

    EM.run do
      request = sns.create_topic name: 'MyTopic'
    
      request.callback do |resp| 
        puts "You created topic #{resp.topic_arn}."
        EM.stop
      end
    
      request.errback do |resp| 
        puts "Amazon returned failure: #{resp.error}."
        EM.stop
      end
    end

### Success Case ###

If the query to Amazon was successful, the `#callback` blocks you attach to the request are run in the order of insertion.  If you passed a block to the query method, it becomes the _first_ callback after **EM::AWS**'s internal handling.  

The blocks are passed an object of a subclass of **EM::AWS::SuccessResponse**, with the values returned by Amazon accessible as attributes. (See the class documentation for more details on specific calls.) 

### Failure Case ###

Transient network failures and Amazon "500" internal errors are automatically retried in the background.  You can tune the number of retries with the `EM::AWS.retries` module attribute.  Successive attempts are delayed a few seconds in a Fibonacci sequence; with the default of 10 retries, the query will ultimately fail after 143 seconds.

Other Amazon errors (or final retry failures) invoke any `#errback` blocks attached to the request, in order of insertion.  The blocks are passed on object subclassed from **EM::AWS::FailureResponse**, with the `#status`, `#code` and `#message` attributes being the interesting attributes to learn about the failure.

There is also an `#exception` method, which returns (but does not raise) an exception object containing the same error data.  The `#exception!` method will _raise_ the exception.  This can be useful if you want to push the failure to more global exception handling mechanisms.  

**IMPORTANT: Attempting to access the response hash or any data attributes on a failure will raise an exception.**  This is to prevent you from confusing a failed response and a successful one.  It's best to keep your _callback_ and _errback_ logic completely separate; if you can't, check the `#success?` attribute before inspecting data.


## Queries Without EventMachine ##

If the EventMachine reactor is not running, **EM::AWS** defaults to a simple synchronous mode.  It will start and stop EventMachine internally, and return the request object to you _after_ the request has succeeded or failed.  The returned data from Amazon can thus be used in your next line of code.

This mode is intended as a convenience for developers who like the clean syntax of **EM::AWS** but don't want to think about EventMachine or callbacks.  _Do not mix this usage with other EventMachine tools or libraries._  **EM::AWS** will stop the event loop without knowledge or regard for anything else, leading to unpredictable results.  If you have other uses for EventMachine, put your calls in the `EM.run` loop and write evented code.  

### Success Case ###

The request object contains the response returned from Amazon (accessible via the `#response` method) and delegates any data access to it.  Working with it is therefore very similar to working with the response in a callback block.   Referencing again the example from earlier up:

    # (EventMachine is not running)
    request = sns.create_topic name: 'MyTestTopic'
    request.success?     #=> true
    request.topic_arn    #=> arn:aws:sns:us-east-1:123456789012:MyTestTopic

If a block was given, that block will be run before the method returns.  If other **EM::AWS** queries are made within that block, EventMachine will not stop until _all_ of them have completed.  (Note, however, that these "inner" queries _will not_ have this magic synchronous behavior, because EventMachine will be running when they are called.)

### Failure Case ###

Failing in synchronous mode will raise an exception containing the error code and message from Amazon.
                            
## General Notes ##

The following behavior is true for all [AWS] services:

* **EM::AWS** uses HTTP POST by default for all Query Protocol calls. You can override it to use GET queries by passing `method: :get` on service initialization. (This will of course limit the amount of data that can be passed.)
* SSL is enabled by default. You can disable it globally with `EM::AWS.ssl = false` or locally by passing `ssl: false` on service object initialization.
* XML response values that include lists of `<member>` elements will be flattened into arrays.
* XML response values that include `<key>` and `<value>` pairs will be flattened into Ruby hashes.
* If any query receives a `Throttling` response from Amazon, it will be retried, and subsequent calls to the same service will be subject to a 1 second delay.  The delay will expire if two minutes pass without a throttling error.

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

[AWS]: http://aws.amazon.com
[DEFER]: http://eventmachine.rubyforge.org/docs/DEFERRABLES.html
[EM]: http://rubyeventmachine.com/
[SNS]: http://aws.amazon.com/sns
[SQS]: http://aws.amazon.com/sqs

## Contributing ##


    
    