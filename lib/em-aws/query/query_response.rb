require 'nokogiri'
require 'em-aws/inflections'
require 'em-aws/query/response_parser'

module EventMachine
  module AWS
    module Query
      
      # Shared behaviors for QueryResult and QueryFailure. The class this is mixed into MUST have a
      # 'ResponseParser' class within its namespace.
      module QueryResponse
        include Inflections
      
        attr_reader :result, :metadata
    
        def initialize(http_response)
          super
          @result, @metadata = {}, {}
          parse @body unless @body.empty?
        end
        
        # Returns the specified key from the inner 'SomeActionResults' data.
        def [](val)
          @result[val] || @result[symbolize(val)]
        end
    
        def request_id
          metadata[:request_id]
        end
    
        def method_missing(name, *args, &block)
          if @result.has_key? name   # Make sure nil values are returned correctly
            @result[name] 
          else
            super
          end
        end
    
        protected
    
        def parse(xml)
          parser = Nokogiri::XML::SAX::Parser.new ResponseParser.new(@result, @metadata)
          parser.parse xml
        end
      end
      
    end
  end
end