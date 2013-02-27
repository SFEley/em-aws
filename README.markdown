# EventMachine::AWS #

**EM::AWS** is an abstract Ruby framework for making calls to [Amazon Web Services][AWS] with [EventMachine][EM].  It transparently signs requests, automatically retries on server errors, and unwraps XML responses into simple attributes. This gem itself does not provide endpoints or object models for any of Amazon's services; it simply provides common functionality for using the [Amazon Query Protocol][AQP]. Other gems or applications may use this foundation to construct API wrappers for specific services.

**EM::AWS** differs from other [EventMachine][EM] libraries by offering a fully synchronous mode that _does not require_ EventMachine to be running. (The query call simply starts and stops EM behind the scenes.) This mode is less efficient but makes it easier to use **EM::AWS** in non-evented frameworks such as Rails.

Gems are currently available for the following services:

* [**SNS** - Simple Notification Service][SNS]
* [**SQS** - Simple Query Service][SQS]

Other services will be added shortly, with the notable exception of S3 (which does not use the Amazon Query Protocol).

## Getting Started ##

The **em-aws** gem is dependent on the **eventmachine**, **em-http-request**, and **nokogiri** gems.  It was built and tested with Ruby 1.9, but should work with Rubinius and JRuby in 1.9 compatibility mode.  _It will not work in Ruby 1.8._  Add it to your Gemfile or run `gem install em-aws` as usual.

If all AWS services in your application use the same credentials and
region, you may supply them globally:

```ruby
require 'em-aws'

EM::AWS.aws_access_key_id = 'YOUR_ACCESS_KEY'
EM::AWS.aws_secret_access_key = 'YOUR_SECRET_KEY'

# These global defaults can also be tweaked:
# EM::AWS.region = 'us-east-1'
# EM::AWS.ssl = true
# EM::AWS.retries = 10
```

If you don't want to supply your credentials globally, or need to use multiple identities in the same application, you can pass any of the above as options when constructing individual service objects:

```ruby
# Basic example using the Simple Notification Service:
sns = EM::AWS::SNS.new

# The tricked-out version:
sns2 = EM::AWS::SNS.new aws_access_key_id: 'OTHER_ACCESS_KEY',
                        aws_secret_access_key: 'OTHER_SECRET_KEY',
                        region: 'ap-southeast-1',
                        ssl: false,
                        method: :get
```

## Making Queries ##

***Note:*** _The following sections describe functionality common to most libraries using **EM::AWS** in its intended manner. See the documentation for specific gems for actual methods and higher-level behavior._

To make any AWS request, simply create a service object of the appropriate class and then call the API action as a method using Ruby *snake_case* conventions.  Parameters are most often passed as a hash:

```ruby
sns = EM::AWS::SNS.new
request = sns.create_topic name: 'MyTestTopic'
```

The request object receives and parses the response, and makes the returned values available as attributes or a hash:

```ruby
request.finished?    #=> true
request.status       #=> 200
request.topic_arn    #=> arn:aws:sns:us-east-1:123456789012:MyTestTopic
request[:topic_arn]  #=> (same)
request['TopicArn']  #=> (same)
```

The request can be passed a block, which -- if the request is successful -- receives the parsed response data and can act on it any way you like (in EventMachine terms, it becomes a _callback_):

```ruby
# Subscribe to the topic once created
sns.create_topic name: 'MyTestTopic' do |response|
  sns.subscribe protocol: 'email', endpoint: 'myself@example.org', topic_arn: response.topic_arn
end
```

This single block usage works in both EventMachine and synchronous modes. (See below.)  If you want to add more than one callback, or handle query failures in an interesting way, you'll need to use EventMachine callbacks and errbacks.

## Queries With EventMachine ##

Inside an `EM.run` loop, calling any query method will return the request object immediately.  The `#finished?` attribute on the request will initially be _false_. The HTTP request will be made and the response received and parsed within the [EventMachine][EM] loop, after which `#finished?` will be _true_.  The `#success?` attribute will then be _true_ if Amazon returned a successful response, or _false_ if an error was received from Amazon.

The **Request** object mixes in the [**EventMachine::Deferrable**][DEFER] module, meaning you can attach blocks using the `#callback` and `#errback` methods.  This is the primary means for event-driven programming with this gem.  

(**Note:** Unless your entire program runs a continuous EventMachine loop, remember to call `EM.stop` when you're finished handling all requests. You will need to do so for both success and failure cases.)

```ruby
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
```

### Success Case ###

If the request to Amazon was successful (i.e. status code 200), the response will first be parsed into an instance of **EM::AWS::SuccessResponse** or a subclass.  The values returned by Amazon will be available as attributes.  This object will be passed to the `#callback` blocks you attach to the request, which will be run in the order of insertion.  If you passed a block to the query method, it becomes the _first_ callback.  

### Failure Case ###

Other Amazon errors (excepting transient failures) invoke any `#errback` blocks attached to the request, in order of insertion.  The blocks are passed an object subclassed from **EM::AWS::FailureResponse**, with the `#status`, `#code` and `#message` attributes giving relevant information from Amazon.

There is also an `#exception` method, which returns (but does not raise) an exception object containing the same error data.  The `#exception!` method will _raise_ the exception.  This is uncommon in EventMachine, but may be useful if you want to push the failure to non-evented exception handlers in your application.


## Queries Without EventMachine ##

If the EventMachine reactor is not running, **EM::AWS** defaults to a simple synchronous mode.  It will start and stop EventMachine internally, and the method call will block until _after_ the request has succeeded or failed.  The request object will be returned by the method, with response data from Amazon available for use in your next line of code.

***IMPORTANT SAFETY TIP, THANKS EGON:***  
This mode is intended as a convenience for developers who want to use gems based on **EM::AWS** but don't want to think about EventMachine or callbacks.  _Do not mix this usage with other EventMachine tools or libraries._  **EM::AWS** will stop the event loop without knowledge or regard for anything else, leading to unpredictable results.  If you have other uses for EventMachine, put your calls in the `EM.run` loop and write evented code.  

### Success Case ###

The request object contains the response returned from Amazon (accessible via the `#response` method) and delegates any data access to it.  Working with it is therefore very similar to working with the response in a callback block.   Referencing again the example from earlier up:

```ruby
# (EventMachine is not running)
request = sns.create_topic name: 'MyTestTopic'
request.success?     #=> true
request.topic_arn    #=> arn:aws:sns:us-east-1:123456789012:MyTestTopic
```

If a block was given, that block will be run before the method returns.  If other **EM::AWS** queries are made within that block, EventMachine will not stop until _all_ of them have completed.  (Note, however, that these "inner" queries _will not_ have this magic synchronous behavior, because EventMachine will be running when they are called. In other words, don't nest queries more than one level deep.)

### Failure Case ###

Failing in synchronous mode will raise an exception of type **EM::AWS::Error** containing the error code and message from Amazon. It's up to you to determine what to do with that exception.
                            
## Transient Failures ##

Network delivery failures and Amazon "500" internal errors are automatically retried in the background.  You can tune the number of retries with the `EM::AWS.retries` module attribute; the default is 10 retries.  

Successive attempts are delayed an increasing number of seconds in a Fibonacci sequence.  I.e., the second retry will happen 1 second after the first; then 2 seconds, then 3, then 5, then 8, etc.  With the default of 10 retries, the query will ultimately fail after 143 seconds.

If any query receives a `Throttling` response from Amazon, it will be retried in the same delay sequence, and _all_ subsequent calls to the same service will be subject to a 1 second delay.  The delay will expire if two minutes pass without a throttling error.

## General Notes ##

The following behavior is true for all [AWS] services:

* HTTP POST is used by default for all Query Protocol calls. You can override it to use GET queries by passing `method: :get` on service initialization. (This will of course limit the amount of data that can be passed.)
* SSL is enabled by default. If for some reason security doesn't appeal to you, you can disable it globally with `EM::AWS.ssl = false` or locally by passing `ssl: false` on service object initialization.
* XML response values that include lists of `<member>` elements will be flattened into arrays.
* XML response values that include `<key>` and `<value>` pairs will be flattened into Ruby hashes.

## SQS ##

The Simple Queue Service behaves differently from most other Amazon services, in that most calls must be made to a _queue URL_ rather than a root path.  This must be supplied on initialization of the **EM::AWS::SQS** object.  If you already know the URL of the queue you want to work with, you can simply pass it with the `:url` parameter:

```ruby
queue = EM::AWS::SQS.new url: 'https://sqs.us-east-1.amazonaws.com/1234567890/My-Interesting-Queue'
```

If you know a queue's name but not its URL, you can use the `.get` class method to call 'GetQueueUrl' and create the proper SQS object:

```ruby
queue = EM::AWS::SQS.get 'My-Interesting-Queue'
```

You can also create a queue that doesn't exist yet using the `.create` class method, passing any optional attributes as a hash:

```ruby
queue = EM::AWS::SQS.create 'My-Interesting-Queue', 
    visibility_timeout: 120,
    maximum_message_size: 8192
```

(If a queue with that name already exists, the `.create` class method has the same net effect as `.get`, except that Amazon will return an error if you pass any attributes that are different from the ones already set.)

[AWS]: http://aws.amazon.com
[DEFER]: http://eventmachine.rubyforge.org/docs/DEFERRABLES.html
[EM]: http://rubyeventmachine.com/
[SNS]: http://aws.amazon.com/sns
[SQS]: http://aws.amazon.com/sqs
[AQP]: http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/using-query-api.html

## Contributing ##


    
