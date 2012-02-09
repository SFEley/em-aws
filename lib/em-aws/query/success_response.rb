require 'em-aws/inflections'
require 'em-aws/query/response'
require 'em-aws/query/response_parser'

module EventMachine
  module AWS
    class Query
    
      class SuccessResponse < Response
        include Inflections
        
        attr_reader :result, :metadata
      
        def initialize(http_response)
          super
          @result, @metadata = {}, {}
          parse @xml unless @xml.empty?
        end
      
        # Returns the specified key from the inner 'SomeActionResults' data.
        def [](val)
          @result[val] || @result[symbolize(val)]
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