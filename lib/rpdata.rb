require "rpdata/version"
require 'savon' 

module Rpdata
  
  AVAILABLE_WSDLS = {
  	property_search: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertySearchService.wsdl",
  	property: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertyService.wsdl", 
	sales: "http://rpp.rpdata.com/bsgAU-2.0/ws/salesService.wsdl",
	on_the_market: "http://rpp.rpdata.com/bsgAU-2.0/ws/onTheMarketService.wsdl"	
  }

  def self.get_property_match( session_token, search_param ) 
  	message = { sessionToken: session_token, :propertyAddressMatch => { :singleLine => search_param } }  
  	client(:property_search).call(:get_property_match, message: message)
  end

  def self.client( key )
  	Savon.client(wsdl: AVAILABLE_WSDLS[key], pretty_print_xml: false)
  end

  def self.available_services
    AVAILABLE_WSDLS.keys
  end



end
