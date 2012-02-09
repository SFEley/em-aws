require 'nokogiri'
require 'em-aws/inflections'

module EventMachine
  module AWS
    class Query
      class Response
        
        # Used for parsing Amazon's XML responses with Nokogiri.
        # Implements the SAX model for fast flexible processing,
        # and populates the relevant hashes in the "parent" response.
        class ResponseParser < Nokogiri::XML::SAX::Document
          include Inflections
                    
          def initialize(result, metadata)
            @result, @metadata = result, metadata
          end

          def start_document
            @stack = []
            @current_string = ''
          end
          
          def start_element(name, attrs=[])
            case name
            when /(.+)Response$/
              @metadata[:action] = $1
            when /(.+)Result$/
              @stack.push @result
            when 'ResponseMetadata'
              @stack.push @metadata
            when 'member'
              @stack.push Array.new unless @stack.last.is_a?(Array)
              @stack.push :member
            else
              @stack.push Hash.new unless @stack.last.is_a?(Hash)
              @stack.push symbolize(name)
            end
            
            # puts "Just started #{name} - #{@stack}"
          end
          
          def characters(str)
            @current_string << str
          end
          
          def cdata_block(str)
            @current_string << str
          end
            
          
          def end_element(name)
            value = coerce_value(@current_string)
            @current_string = ''
            collapse_stack(value)
            # puts "Just finished #{name} - #{@stack}"
          end
                
          private
          
          def collapse_stack(value)
            case element = @stack.pop
            when :member    # Add to the array
              @stack.last << value
            when :entry     # Add 'key'/'value' elements to the hash
              @stack.last[value[:key]] = value[:value]
            when Symbol
              if @stack.last.is_a?(Hash)
                @stack.last[element] = value
              else 
                raise "I don't know how to add #{element} to #{@stack}"
              end
            else
              collapse_stack element unless @stack.empty?
            end
          end
              
          def coerce_value(val)
            case val.strip!
            when '' then nil
            when /\A[-+]?\d+\Z/ then val.to_i
            when /\A[-+]?\d+\.\d+\Z/ then val.to_f
            else val
            end
          end
              
            
          
        end
      end
    end
  end
end