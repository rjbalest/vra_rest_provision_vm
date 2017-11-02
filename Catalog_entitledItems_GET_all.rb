# Add the local directory to the library path
libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'VMWConfig'

url = VMW::API::URI('/catalog-service/api/consumer/entitledCatalogItemViews')

begin
  response = VMW::API::sign {
    RestClient.get url, :content_type => :json
  }

  payload = VMW::Payload.from_json(response)
  payload.save_json('catalog_entitled_items.json')

  # Print a summary
  payload.doc['content'].each do |item|
    catalogItemId = item['catalogItemId']
    print "%-30s%-60s%-20s%-20s\n" % [ item['name'], item['catalogItemTypeRef']['id'], item['catalogItemTypeRef']['label'],catalogItemId]
    # iterate through entitled organizations
    item['entitledOrganizations'].each do |org|
      subtenantRef = org['subtenantRef']
      subtenantLabel = org['subtenantLabel']
      print "%80s%40s\n" % [subtenantLabel,subtenantRef]
    end
  end

rescue RestClient::Exception => e
  print "Got exception with status: %d\n" % e.response.code
  print "%s\n" % e.response
end
