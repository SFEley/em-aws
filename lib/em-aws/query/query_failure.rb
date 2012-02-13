require 'nokogiri'
require 'em-aws/response'
require 'em-aws/query/query_error'
require 'em-aws/query/query_response'

module EventMachine
  module AWS
    module Query
      
      class QueryFailure < FailureResponse
        include QueryResponse
        
        def [](val)
          super or exception!
        end
        
        def error
          result[:code]
        end
        
        def exception
          QueryError.new(status, @result[:code], @result[:message])
        end
        
        def exception!
          raise exception, exception.message
        end
        
        def method_missing(name, *args, &block)
          @result[name] or exception!
        end
          
      end
      
    end
  end
end