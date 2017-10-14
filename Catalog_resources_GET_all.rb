# Add the local directory to the library path
libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'VMWConfig'

url = VMW::API::URI('/catalog-service/api/consumer/resources')
requestId = 'e493b236-561e-45e2-896b-ada9e16617f9'
resourceId = nil
ipAddress = nil

begin
  response = VMW::API::sign {
    RestClient.get url, :content_type => :json
  }

  payload = VMW::Payload.from_json(response)
  payload.save_json('catalog_resources.json')

  # Print a summary and fetch resource Id
  payload.doc['content'].each do |item|
    if item['requestId'] == requestId
      print "%-50s%-60s%-20s\n" % [ item['id'], item['resourceTypeRef']['id'], item['resourceTypeRef']['label']]
      if item['resourceTypeRef']['id'] == 'Infrastructure.Virtual'
        resourceId = item['id']
      end
    end
  end

  # Now get specific resource
  if resourceId
    url = VMW::API::URI("/catalog-service/api/consumer/resources/%s" % resourceId)

    response = VMW::API::sign {
      RestClient.get url, :content_type => :json
    }

    payload = VMW::Payload.from_json(response)
    payload.save_json("catalog_resource_%s.json" % resourceId)

    # Get the IP Address
    payload.doc['resourceData']['entries'].each do |item|
      if item['key'] == 'ip_address'
        ipAddress = item['value']['value']
        print "IP Address: %s\n" % ipAddress
      end
      if item['key'] == 'MachineName'
        print "Name: %s\n" % item['value']['value']
      end
    end
  end

rescue RestClient::Exception => e
  print "Got exception with status: %d\n" % e.response.code
  print "%s\n" % e.response
end
