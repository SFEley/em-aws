require "bundler/gem_tasks"
$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'em-aws'


namespace :clean do
  EM::AWS.aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
  EM::AWS.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

  desc "Deletes any leftover SQS queues (EM-AWS-Test-Queue-*)"
  task :queues do
    EM.run do
      q = EM::Queue.new
      sqs = EM::AWS::SQS.new
      puts "Retrieving test queues..."
      list = sqs.list_queues(queue_name_prefix: 'EM-AWS-Test-Queue') 
      list.callback {|r| q.push *Array(r[:queue_url])}
      list.errback do |r|
        puts "ERROR: #{r.error}"
        EM.stop
      end
      
      EM.add_periodic_timer(0.1) do 
        q.pop do |url|
          puts "Deleting #{url}..."
          queue = EM::AWS::SQS.new url: url
          del = queue.delete_queue 
          del.callback {|r| puts "  --Deleted #{url}"}
          del.errback do |r| 
            puts "  **ERROR: #{r.error} on #{url}"
            q.push url
          end
        end
      end
      
      EM.add_periodic_timer(5) do
        if q.empty?
          puts "All queues deleted."
          EM.stop
        end
      end
        
    end
  end
  
end