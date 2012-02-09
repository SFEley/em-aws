require 'uri'
require 'openssl'
require 'base64'

module EventMachine
  module AWS
    class Query
      
      # Encapsulates the logic to add authentication attributes to AWS requests.
      class SignatureV2
        attr_reader :access_key, :secret_key, :method, :host, :path
      
        def initialize(access_key, secret_key, method, endpoint)
          @access_key = access_key
          @secret_key = secret_key
          @method = method
          if endpoint =~ %r!^(https?://)?([^/]+)(/[^?]*)!
            @host, @path = $2, $3
          end
        end
      
        # Adds the Query Protocol authentication headers
        def signature(params)
          signature_params = {
               AWSAccessKeyId: access_key,
               SignatureVersion: 2,
               SignatureMethod: 'HmacSHA256'
             }
          param_string = signable_params params.merge(signature_params)
          signature_params[:Signature] = hmac_sign param_string
          signature_params
        end
            
        # Implements the AWS signing method, version 2 (HMAC digest then Base64 encoded) with the secret key
        # See: http://docs.amazonwebservices.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/Query_QueryAuth.html
        def hmac_sign(str)
          hmac = OpenSSL::HMAC.digest('sha256', secret_key, str)
          Base64.strict_encode64 hmac
        end
      
        # Lines up and encodes our parameters nicely and neatly in sorted order
        def signable_params(params)
          if method == :get
            param_array = params.collect{|pair| "#{uri_escape(pair[0])}=#{uri_escape(pair[1])}"}
          else
            param_array = params.collect{|pair| "#{form_escape(pair[0])}=#{form_escape(pair[1])}"}
          end
          param_string = param_array.sort.join('&')
          "#{method.to_s.upcase}\n#{host}\n#{path}\n#{param_string}"
        end

        private
      
        # # URI escape according to the character set that's legal in RFC 3986
        # (and the AWS EC2 User Guide, v2011-05-15, p.338)
        def uri_escape(val)
          URI.escape(val.to_s, /[^A-Za-z0-9\-_.~]/)
        end

        def form_escape(val)
          URI.encode_www_form_component(val.to_s)
        end
      end
      
    end
  end
end
