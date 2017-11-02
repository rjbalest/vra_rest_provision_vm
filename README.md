# vra_rest_provision_vm
Provision VM via vRA REST API

Assuming ruby is installed, 2 gems are required:

- sudo gem install rest-client
- sudo gem install nokogiri

Copy VMWConfig.rb_T to VMWConfig.rb

Edit the following lines appropriately:

- VMW::API::baseURI = nil
- VMW::API::userName = nil
- VMW::API::password = nil 
- VMW::API::tenant = nil 

For example:

- VMW::API::baseURI = "http://myvra.vmw.com"
- VMW::API::userName = "admin"
- VMW::API::password = "mypasswd"
- VMW::API::tenant = "my vra tenant name"

Edit vmRequest.rb

Minimally, change these lines:

- blueprintName = "centos"
- businessGroup = "Ford"
- customizationSpec = "Linux"

Run the request:

- ruby ./vmRequest.rb

This command should invoke a vRA blueprint and monitor
it's progress until it completes.  

After completion, it polls the newly
created vRA item until an IP address shows up in the vRA inventory, which can be 5 or 15 minutes later.
