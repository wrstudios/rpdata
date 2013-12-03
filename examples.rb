

#gem installation
#gem install savon --version '~> 2.0'


require 'savon'

client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertySearchService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations.

message = { sessionToken: "49998-fb7f5f1266184b7265901551974dd4f1", :propertyAddressMatch => { :singleLine => "380 David Low Way" } }  
response = client.call( :get_property_match, :message => message  )




#Trying to get property by id.
client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertyService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations.

message = { sessionToken: "49998-fb7f5f1266184b7265901551974dd4f1", :propertyId => "6817048" }  
client.call(:get_property_detail, :message => message)
client.call(:get_property_summary, :message => message)
client.call(:get_property_profile_report, :message => message)


client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/salesService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations.
message = { sessionToken: "49998-fb7f5f1266184b7265901551974dd4f1", :propertyId => "6817048" }  
client.call(:get_sale_detail, :message => message) # It didn't bring anything different than get_property_detail in the propertyService wsdl.



client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/onTheMarketService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations.
message = { sessionToken: "49998-fb7f5f1266184b7265901551974dd4f1", :propertyId => "6817048" }  
client.call(:get_listings_for_property_id, :message => message) 
