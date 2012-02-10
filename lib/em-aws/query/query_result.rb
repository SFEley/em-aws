require 'nokogiri'
require 'em-aws/response'
require 'em-aws/query/query_response'

module EventMachine
  module AWS
    module Query
        
      class QueryResult < SuccessResponse
        include QueryResponse
        
        def action
          metadata[:action]
        end

      end
    end
  end
end