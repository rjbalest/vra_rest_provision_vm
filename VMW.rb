require 'rest-client'
require 'openssl'
require 'base64'
require 'json'
#require 'URI'

# locally:
# cp VMW.rb /usr/share/ruby/2.0.0/

module VMW

class API
  
  @@username = 'admin'
  @@password = 'admin'
  @@tenant = 'qe'

  @@apiKey = nil
  @@apiSecret = nil

  @@in_login = false
  @@auto_auth = false

  @@baseURI = nil
  @@debug = false

  @@sslVerify = true

  def self.sslVerify
    @@sslVerify
  end
  def self.sslVerify=(torf)
    @@sslVerify=torf
  end

  def self.userName=(username)
    @@username = username
  end

  def self.password=(password)
    @@password = password
  end

  def self.tenant=(tenant)
    @@tenant = tenant
  end

  def self.debug
    @@debug
  end

  def self.debug=(value)
    @@debug = value
  end

  def self.generateAuthHeaders( uriPath, httpMethod, userAgent, apiKey=nil, apiSecret=nil )
    headers = {}
    apiKey = apiKey || @@apiKey
    apiSecret = apiSecret || @@apiSecret

    timestamp = Time.now.to_i.to_s
    requestString = "%s:%s:%s:%s:%s" % [apiKey,httpMethod,uriPath,userAgent,timestamp]
    hash_str = OpenSSL::HMAC.digest('sha256',apiSecret,requestString)
    signature = Base64.strict_encode64(hash_str)
    
    if @@debug
      print "request string: %s\n" % requestString
      #print "hash: %s\n" % hash_str
      print "signature: %s\n" % signature
      print "apiKey: %s\n" % apiKey
      print "apiSecret: %s\n" % apiSecret
      print "timestamp: %s\n" % timestamp
    end

    #headers['x-dell-auth-key'] = apiKey
    #headers['x-dell-auth-signature'] = signature
    #headers['x-dell-auth-timestamp'] = timestamp
    headers['Authorization'] = "Bearer %s" % apiKey
    headers
  end
  
  def self.injectAuthHeaders( request )

    if @@apiSecret.nil? and @@apiKey.nil?
      self.login(@@username,@@password,@@tenant)
    end

    userAgent = request['user-agent']
    httpMethod = request.method
    
    # Strip query string from path, which is really a uri
    uri = URI::parse(request.path)
    uriPath = uri.path
    
    auth_headers = generateAuthHeaders( uriPath, httpMethod, userAgent, @@apiKey, @@apiSecret)

    # Add headers to request
    auth_headers.keys.each do |key|
      request[key] = auth_headers[key]
    end

  end

  def self.login(user, pass, tenant)
    # Login
    @@apiSecret = 'in progress'
    json = "{\"tenant\": \"%s\", \"username\": \"%s\", \"password\": \"%s\"}" % [tenant,user,pass]
    @@in_login = true
    response = RestClient.post "#{@@baseURI}/identity/api/tokens", json, :content_type => :json, :accept => :json
    @@in_login = false
    h = JSON.parse( response.body )
    if @@debug
      print "Response: %s" % response
      print "Response body: %s" % response.body
    end
    @@apiKey = h['id']
    @@apiSecret = h['id']
  end

  def self.logout
    # Invalidate creds
    @@apiSecret = nil
    @@apiKey = nil
  end

  def self.sign(user=nil,pass=nil)
    @@username = user unless user.nil?
    @@password = pass unless pass.nil?

    self.disableAutoAuth
    self.enableAutoAuth
    result = yield
    self.disableAutoAuth
    return result
  end

  def self.disableAutoAuth
    @@auto_auth = false
    RestClient.reset_before_execution_procs
  end

  def self.enableAutoAuth
    @@auto_auth = true
    RestClient.add_before_execution_proc do |request, params|
      if @@auto_auth
        # guard against infinite recursion     
        #print "In_login = #{@@in_login}\n"
        #if request['signed']
        if true
          injectAuthHeaders(request) unless @@in_login
        else
          print "Not signing request\n"
        end
      end
    end
  end

  def self.baseURI=(url)
    @@baseURI = url
  end

  def self.URI(path)
    "%s%s" % [@@baseURI,path]
  end
end

end
