

#gem installation
#gem install savon --version '~> 2.0'


require 'savon'

#SessionService. Authentication.
client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/sessionService.wsdl", pretty_print_xml: true)
client.operations
message = { userName: 'bsguser.iproperty', password: 'x5yGCV85'}
client.call(:get_customers_for_user, message: message ).body


#message = { userName: 'bsguser.iproperty', password: 'x5yGCV85', customerId: '500998' , integratorId: '43376848'}
client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/sessionService.wsdl", pretty_print_xml: true)
message = { userName: 'bsguser.iproperty', password: 'x5yGCV85', customerId: '500998' , integratorId: '43376848'}
@session_token = client.call(:generate_integrator_auth_token, message: message ).body[:generate_integrator_auth_token_response][:token]

client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertySearchService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations

message = { sessionToken: @session_token, :propertyAddressMatch => { :singleLine => "3/19 Jarnahill Drive, Mount Coolum" } }
response = client.call( :get_property_match, :message => message  ).body

#Trying to get property by id.
client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertyService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations.

message = { sessionToken: @session_token, :propertyId => "6168318" }
client.call(:get_property_detail, :message => message)
client.call(:get_property_summary, :message => message)
client.call(:get_property_profile_report, :message => message)

message = { sessionToken: @session_token, :searchString => "380 David Low Way" }
client.call(:get_suggestion_list, :message => message)

client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/salesService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations.
message = { sessionToken: @session_token, :propertyId => "6817048" }
client.call(:get_sale_detail, :message => message) # It didn't bring anything different than get_property_detail in the propertyService wsdl.


client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/onTheMarketService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations.
message = { sessionToken: @session_token, :propertyId => "6817048" }
client.call(:get_listings_for_property_id, :message => message)


#search - Stoped here. test this search endpoint for RecentSales and On the market.
client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertySearchService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations.
message = { sessionToken: @session_token, :searchAreaCriteria => {postcode: "4566"}, fetchProperties: true }
client.call(:search, message: message)


#images.
client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertyImageryService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations.
message = { sessionToken: @session_token, propertyId: "6817048" }
client.call(:get_photos, message: message)


#valueers

#search - Stoped here. test this search endpoint for RecentSales and On the market.
client = Savon.client(wsdl: "http://rpp.rpdata.com/bsgAU-2.0/ws/valuersService.wsdl", pretty_print_xml: true)
client.operations #outputs the available operations.
message = { sessionToken: @session_token, propertyId: "6168318", fetchPropertySalesHistory: true , fetchPropertyOTMHistory: true, fetchPropertyOTMRentalHistory: true, fetchPropertyComparableSales: true, fetchPropertyComparableOTMs: true, fetchPropertyMarketComparisons: true, fetchPDF: true}
client.call(:get_valuers, message: message)
