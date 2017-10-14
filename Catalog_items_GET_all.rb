require './VMWConfig'

url = VMW::API::URI('/catalog-service/api/catalogItems')

begin
  response = VMW::API::sign {
    RestClient.get url, :content_type => :json
  }

  payload = VMW::Payload.from_json(response)
  payload.save_json('catalog_items.json')

  # Print a summary
  payload.doc['content'].each do |item|
    print "%-30s%-60s%-20s\n" % [ item['name'], item['catalogItemTypeRef']['id'], item['catalogItemTypeRef']['label']]
  end

rescue RestClient::Exception => e
  print "Got exception with status: %d\n" % e.response.code
  print "%s\n" % e.response
end
