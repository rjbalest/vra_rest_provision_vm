require 'VMW'
require 'VMWPayload'

VMW::API::baseURI = nil 

VMW::API::userName =  nil
VMW::API::password = nil 
VMW::API::tenant = nil 

VMW::API::debug = false

# Set this to always require authentication on every http request
#VMW::API::autoEnableAuth

# Set this to false if want to ignore problems with self-signed certs.
VMW::API::sslVerify = false

VMW::Payload.basePath = './payloads'

# hack to deal with self-signed certificates
module RestClient
  class Request
    def self.execute(args, & block)
      unless VMW::API::sslVerify
        args[:verify_ssl] = false
      end
      new(args).execute(& block)
    end
  end
end
