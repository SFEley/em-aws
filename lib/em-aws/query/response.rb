require 'em-aws/query/response_parser'

module EventMachine
  module AWS
    class Query
    
      # Exposes the result values from an Amazon Query Protocol XML response as a hash or 
      # as dynamic methods. 
      class Response
      
        attr_reader :header, :xml, :result, :metadata
        
        def initialize(http_response)
          @header = http_response.response_header
          @xml = http_response.response
          @result, @metadata = {}, {}
          parse @xml unless @xml.empty?
        end
        
        # Returns the specified key from the inner 'SomeActionResults' data.
        def [](val)
          @result[val]
        end
        
        def action
          metadata[:action]
        end
        
        def request_id
          metadata[:request_id]
        end
        
        def method_missing(name, *args, &block)
          @result[name] or super
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