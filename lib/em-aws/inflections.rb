module EventMachine
  module AWS
    
    # Utility methods to convert names between AWS CamelCaseConventions and Ruby :snake_case_conventions.
    module Inflections
      private

      def snakecase(name)
        # Adapted from ActiveSupport's #underscore method
        name.to_s.gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').downcase
      end
      
      def symbolize(name)
        snakecase(name).to_sym
      end

      def camelcase(name)
        # Adapted from ActiveSupport's #camelize method
        name.to_s.gsub(/(?:^|_)(.)/) { $1.upcase }
      end
        
    end
    
  end
end