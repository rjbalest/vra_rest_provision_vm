# Add the local directory to the library path
libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'VMWConfig'

# Request the vRA 'centos' blueprint
blueprintName = "centos"
businessGroup = "Ford"
numCpus = 1
customizationSpec = "Linux"

if ARGV[0]
  blueprintName = ARGV[0]
end

if ARGV[1]
  numCpus = ARGV[1]
end

catalogItemId = nil
businessGroupId = nil

# GET entitled catalog items
url = VMW::API::URI('/catalog-service/api/consumer/entitledCatalogItemViews')

begin
  response = VMW::API::sign {
    RestClient.get url, :content_type => :json, :params => {:$filter => "name eq '%s'" % blueprintName}
  }

  payload = VMW::Payload.from_json(response)

  # Retrieve the blueprint id
  item = payload.doc['content'].first
  catalogItemId = item['catalogItemId']
  print "Found blueprint: %-30s%-60s%-20s%-20s\n" % [ item['name'], item['catalogItemTypeRef']['id'], item['catalogItemTypeRef']['label'],catalogItemId]

  # iterate through entitled organizations
  item['entitledOrganizations'].each do |org|
    subtenantRef = org['subtenantRef']
    subtenantLabel = org['subtenantLabel']
    if (subtenantLabel == businessGroup)
      print "Found organization: %80s%40s\n" % [subtenantLabel,subtenantRef]
      businessGroupId = subtenantRef
    end
  end

  # Retrieve the input template for this blueprint
  url = VMW::API::URI("/catalog-service/api/consumer/entitledCatalogItems/%s/requests/template" % [catalogItemId])

  response = VMW::API::sign {
    RestClient.get url, :content_type => :json, :params=>{:businessGroupId=>businessGroupId}
  }

  payload = VMW::Payload.from_json(response)
  template = payload.doc

  # Modify the template parameters
  # // data/centos/data/cpu
  template['data']['centos']['data']['cpu'] = 1
  template['data']['centos']['data']['guest_customization_specification'] = customizationSpec
  template['data']['centos']['data']['description'] = "Requested via API"

  # Save it for inspection
  if VMW::API::debug
    pp = VMW::Payload.new(template, :json)
    pp.save_json("catalog_entitleditem_modified_template.json" % [catalogItemId])
  end

  # Invoke the blueprint
  url = VMW::API::URI("/catalog-service/api/consumer/entitledCatalogItems/%s/requests" % [catalogItemId])

  response = VMW::API::sign {
    RestClient.post url, template.to_json, :content_type => :json, :params=>{:businessGroupId=>businessGroupId}
  }

  payload = VMW::Payload.from_json(response)
  request = payload.doc
  requestId = request["id"]

  print "RequestId: %s blueprint %s with %d CPU\n" % [requestId, blueprintName, numCpus]

  requestState = nil
  while not ["SUCCESSFUL", "FAILED"].include? requestState

    # Monitor status of request
    url = VMW::API::URI("/catalog-service/api/consumer/requests/%s" % [requestId])

    response = VMW::API::sign {
      RestClient.get url, :content_type => :json
    }

    payload = VMW::Payload.from_json(response)
    request = payload.doc
    requestState = request["state"]
    print "Request State is: %s\n" % requestState

    sleep 10
  end

  # Save the request for inspection
  payload.save_json("catalog_request_%s.json" % [requestId])

  # Fetch the resource in order to determine the IP address
  url = VMW::API::URI('/catalog-service/api/consumer/resources')

  # Rather than getting all resources, only those that are children of the given request:?
  #/catalog-service/api/consumer/requests/7aaf9baf-aa4e-47c4-997bedd7c7983a5b/resourceViews

  resourceId = nil
  ipAddress = nil

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

    while ipAddress.nil? or ipAddress.empty?
      sleep(30)

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
  end

  # Write results to a file
  File.open("ip_address", "w").write(ip_address)

rescue RestClient::Exception => e
  print "Got exception with status: %d\n" % e.response.code
  print "%s\n" % e.response
end
