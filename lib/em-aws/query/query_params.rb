require 'em-aws/inflections'

module EventMachine
  module AWS
    module Query
      module QueryParams
        include Inflections
        

        def queryize_params(hash)
          out = {}
          hash.each do |k, v|
            k = 'Attribute' if k == :attributes    # Allow plural for readability
            key = camelkey(k)
            case v
            when Hash
              out.merge! flatten_subhash(key, v)
            when Array
              out.merge! flatten_subarray(key, v)
            else
              out[key] = v
            end
          end
          out
        end

      private
        
        # Convert {name: 'value'} hashes to Attribute.n.Name and Attribute.n.Value pairs.
        # Complex values are given further subnames.
        def flatten_subhash(key, hash)
          out = {}
          hash.each_with_index do |arr, i|
            index = i + 1
            name, value = *arr
            out["#{key}.#{index}.Name"] = camelkey(name)
            if value.is_a?(Hash)
              value.each {|k, v| out["#{key}.#{index}.#{camelkey(k)}"] = v}
            else
              out["#{key}.#{index}.Value"] = value
            end
          end
          out
        end
        
        def flatten_subarray(key, array)
          out = {}
          array.each_with_index do |elem, i|
            index = i + 1
            out["#{key}.#{index}"] = elem
          end
          out
        end
        
        def camelkey(k)
          k.is_a?(Symbol) ? camelcase(k) : k
        end

        
      end
    end
  end
end

