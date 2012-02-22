require 'em-aws/query'

module EventMachine
  module AWS
    
    # NOTE: If you want to work with an individual queue, be sure to specify either the 
    # :url parameter for the queue URL or the :queue_name.
    class SQS < Service
      include Query
      
      API_VERSION='2011-10-01'
      
      def queue_name
        url[/https?:\/\/.*?\/(.+)/,1]      
      end
      
      # Retrieves an SQS object by queue name. Returns nil if the queue can't be found.
      def self.get(name)
        url, retriever = nil, self.new
        retriever.get_queue_url(queue_name: name) {|r| url = r.queue_url}
        if url
          self.new url: url
        else
          nil
        end
      end
      
      # Creates a queue by name and returns an SQS object pointing to it.  This operation
      # is idempotent (i.e. will return the same object) if the queue name already exists,
      # so long as no attributes are different.
      def self.create(name, attributes={})
        url, creator = nil, self.new
        creator.create_queue(queue_name: name, attributes: attributes) {|r| url = r.queue_url}
        if url
          self.new url: url
        else
          nil
        end
      end
    end
  end
end