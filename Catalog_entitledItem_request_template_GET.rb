# Add the local directory to the library path
libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'VMWConfig'

catalogItemId = "5a1a50e2-4d4b-47ea-bb4b-0304cde43ee5"
businessGroupId = "06bc849b-80a6-4bcd-8fd4-bc3af0f5a6df"

url = VMW::API::URI("/catalog-service/api/consumer/entitledCatalogItems/%s/requests/template" % [catalogItemId])

begin
  response = VMW::API::sign {
    RestClient.get url, :content_type => :json, :params=>{:businessGroupId=>businessGroupId}
  }

  payload = VMW::Payload.from_json(response)
  payload.save_json("catalog_entitleditem_%s_request_template.json" % [catalogItemId])

  # Print a summary

rescue RestClient::Exception => e
  print "Got exception with status: %d\n" % e.response.code
  print "%s\n" % e.response
end
