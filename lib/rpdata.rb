##
# The idea of this Module is to abstract the comunication with the RPData API

require "rpdata/version"

require 'savon' 
require 'ostruct'
module Rpdata

    
  AVAILABLE_WSDLS = {
  	property_search: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertySearchService.wsdl",
  	property: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertyService.wsdl", 
	  sales: "http://rpp.rpdata.com/bsgAU-2.0/ws/salesService.wsdl",
	  on_the_market: "http://rpp.rpdata.com/bsgAU-2.0/ws/onTheMarketService.wsdl"	,
    session: "http://rpp.rpdata.com/bsgAU-2.0/ws/sessionService.wsdl",
    imagery: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertyImageryService.wsdl",
    valuers: "http://rpp.rpdata.com/bsgAU-2.0/ws/valuersService.wsdl",
    property_statistics: "http://rpp.rpdata.com/bsgAU-2.0/ws/propertyStatisticsService.wsdl"

  }

  ##
  # Returns a suggestion list based on a +search_param+ 
  # 
  # Example: '6/380 Smith street, Vic 3058'
  #
  #
  # Raises an ArgumentError if +search_param+ is not provided.
  #
  def self.suggestion_list( session_token, search_param ) 
    raise ArgumentError if search_param.blank? 
  	message = { sessionToken: session_token, :propertyAddressMatch => { :singleLine => search_param } }  
  	validating_response client(:property_search).call(:get_property_match, message: message).body[:get_property_match_response]
  end

  def self.generate_token(username, password, client_id, integrator_id)
    message = { userName: username, password: password, customerId: client_id , integratorId: integrator_id}
    body = client(:session).call(:generate_integrator_auth_token, message: message ).body
    if body[:generate_integrator_auth_token_response][:messages][:message_type] == "Success"
      body[:generate_integrator_auth_token_response][:token]
    else
      raise SomeError
    end
  end

  def self.suburb_stats( session_token, suburb, postcode, state )
    options = { showNumberSold12Mths: true, showMedianSalePrice: true, showMedianPriceChange12Mths: true, showMedianAskingRent: true, showTotalListings12Mths: true, showTimeOnMarketDays: true }
    message = { sessionToken: session_token, country: "AUS", categoryMjr: "HO", yearFrom: "2013", period: "10" , suburb: suburb , postcode: postcode, state: state, :propertyStatisticsOptions => options }  
    body = client(:property_statistics).call(:get_suburb_statistics, message: message).body
    response = body[:get_suburb_statistics_response]
    OpenStruct.new({
      number_sold_12_mths: response[:number_sold_12_mths],
      median_sale_price: response[:median_sale_price],
      median_price_change_12_mths: response[:median_price_change_12_mths],
      median_asking_rent: response[:median_asking_rent],
      total_listings12_mths: response[:total_listings12_mths],
      time_on_market_days: response[:time_on_market_days]
    })
  end

  def self.id_for_address( session_token, suggestion_string )
    id = suggestion_list(session_token, suggestion_string)[:property_address_match][:property_id] rescue nil
    id ||= suggestion_list(session_token, suggestion_string)[:suggestions].first[:property_id] 
    id
  end

  ##
  # Returns the property summary.
  # 
  # Raises an ArgumentError if +rp_data_property_id+ is not provided.
  #
  def self.property_summary( session_token , rp_data_property_id )
    with_valid_id(rp_data_property_id) do
      message = { sessionToken: session_token, propertyId: rp_data_property_id }  
      response_hash = client(:property).call(:get_property_summary, message: message).body    
      response_hash[:get_property_summary_response][:property_summary]
    end
  end

  ##
  # Returns a list of property photos. 
  # 
  # 
  def self.property_photos( session_token, rp_data_property_id )
    with_valid_id(rp_data_property_id) do 
      photos = []
      message = { sessionToken: session_token, propertyId: rp_data_property_id }
      response = client(:imagery).call(:get_photos, message: message).body
      response[:get_photos_response ][:photo].each do |photo_node|
        photos << OpenStruct.new( large_url: photo_node[:large_image_display_url] , medium_url: photo_node[:medium_image_display_url], small_url: photo_node[:small_image_display_url] , scan_date: photo_node[:scan_date])
      end
    end
  end

  ##
  # Returns the property details.
  # 
  # Raises an ArgumentError if +rp_data_property_id+ is not provided.
  #
  def self.property_details( session_token , rp_data_property_id )
    property_details = OpenStruct.new( sale_history: [], market_sale_history: [], market_rental_history: [])
    with_valid_id(rp_data_property_id) do 
      message = { sessionToken: session_token, propertyId: rp_data_property_id }  
      body = client(:property).call(:get_property_detail, message: message).body
      response = body[:get_property_detail_response][:property]

      if response[:sales_history_list].is_a?(Array)
        property_details.sale_history = response[:sales_history_list]
      else  
        property_details.sale_history << response[:sales_history_list]
      end
      if response[:listing_list].is_a?(Array)
        property_details.market_sale_history = response[:listing_list]  
      else
        property_details.market_sale_history << response[:listing_list]
      end
      if response[:rental_list].is_a?(Array)
        property_details.market_rental_history = response[:rental_list]
      else
        property_details.market_rental_history << response[:rental_list]
      end
    
      property_details
    end
  end

  ##
  # Returns the sale history for a property.
  # 
  # Raises an ArgumentError if +rp_data_property_id+ is not provided.
  #
  def self.sale_detail( session_token, rp_data_property_id )
    with_valid_id(rp_data_property_id) do  
      message = { sessionToken: session_token, propertyId: rp_data_property_id }
      response_hash = client(:sales).call(:get_sale_detail, message: message).body
      p = response_hash[:get_sale_detail_response][:sold_property]
      OpenStruct.new( photo: p[:property_default_photo][:large_url], address: p[:property_address][:address] ,
                      sale_date: p[:transfer_date] , sale_method: p[:transfer_type] , price: p[:transfer_price] , attributes: p[:property_attributes][:property_attribute_summary] )
    end
  end

  def self.property_history( session_token, rp_data_property_id )
    property_history = OpenStruct.new( sale_history: [], otm_sale_history: [], otm_rental_history: [] )
    with_valid_id(rp_data_property_id) do  
      message = { sessionToken: session_token, propertyId: rp_data_property_id, fetchPropertySalesHistory: true , fetchPropertyOTMHistory: true, fetchPropertyOTMRentalHistory: true}
      hash = client(:valuers).call(:get_valuers, message: message).body
      property_sales = hash[hash.keys.first][:property_sales_history][:property_sales]
      if property_sales.is_a?(Array)
        property_sales.each do |ps|
          property_history.sale_history << OpenStruct.new({ vendor: ps[:vendors_name], purchaser: ps[:purchaser_name], sale_date: ps[:sale_date], sale_type: ps[:sale_type], sale_price: ps[:sale_price], settlement_date: ps[:settlement_date] })
        end
      else
        ps = property_sales #This piece of code needs refactoring.
        property_history.sale_history << OpenStruct.new({ vendor: ps[:vendors_name], purchaser: ps[:purchaser_name], sale_date: ps[:sale_date], sale_type: ps[:sale_type], sale_price: ps[:sale_price], settlement_date: ps[:settlement_date] })
      end
      
      otms = hash[hash.keys.first][:property_otm_history][:property_ot_ms] rescue []
      if otms.is_a?(Array)
        otms.each do |otm| 
          property_history.otm_sale_history << OpenStruct.new({ listed_date: otm[:listed_date], listed_sale_type: otm[:listed_sale_type],
           listed_sale_price: otm[:listed_sale_price], listed_sale_price_description: otm[:listed_sale_price_description],
            agency: otm[:agency], agent: otm[:agent], days_listed: otm[:days_listed] })
        end
      else
        otm = otms
        property_history.otm_sale_history << OpenStruct.new({ listed_date: otm[:listed_date], listed_sale_type: otm[:listed_sale_type],
           listed_sale_price: otm[:listed_sale_price], listed_sale_price_description: otm[:listed_sale_price_description],
            agency: otm[:agency], agent: otm[:agent], days_listed: otm[:days_listed] })
      end

      ( hash[hash.keys.first][:property_otm_rental_history][:property_otm_rentals] rescue [] ).each do |por|
        property_history.otm_rental_history << OpenStruct.new({ listed_date: por[:listed_date], listed_price: por[:listed_price], agency: por[:agency], agent: por[:agent], days_listed: por[:days_listed] })
      end

    end
    property_history
  end
  
  def self.fetch_property( session_token, rp_data_property_id )
    with_valid_id(rp_data_property_id) do 
      message = { sessionToken: session_token, propertyIdInput: { propertyIdList: rp_data_property_id }, fetchProperties: true, propertiesCriteria: {mappingDetailsOnly: false, pageNumber: 1, pageSize: 50} }
      response_hash = client(:property_search).call(:search, message: message).body
      property_hash = response_hash[:search_response][:property_search_properties_result][:property_search_properties]
      puts "fetch property"
      puts property_hash.inspect
      OpenStruct.new(property_id: property_hash[:property_id], longitude: property_hash[:longitude], 
                     latitude: property_hash[:latitude], property_type: property_hash[:property_type],
                     avm: property_hash[:auto_value_estimate], bedrooms: property_hash[:property_attributes][:bedrooms], 
                     bathrooms: property_hash[:property_attributes][:bathrooms], car_spaces: property_hash[:property_attributes][:car_spaces])
    end
  end

  def self.property_ids_by_nearest_suburb( session_token, rp_data_property_id )
    with_valid_id(rp_data_property_id) do 
      message = { sessionToken: session_token , propertyId: rp_data_property_id, nearestNeighbourLimit: 5000 }
      response_hash = client(:property).call(:get_property_ids_by_nearest_neighbour, message: message ).body
      response_hash[:get_property_ids_by_nearest_neighbour_response][:nearest_neighbours].collect do |hash| 
        OpenStruct.new property_id: hash[:property_id], distance_from_target: hash[:distance_from_target]
      end
    end
  end

  def self.refine_sold_properties( session_token, ids_list, target_property )
    message = { sessionToken: session_token, bedrooms: target_property.bedrooms, propertyTypes: target_property.property_type, 
               lastSalePriceFrom: (target_property.avm * 0.85 ) , lastSalePriceTo: (target_property.avm * 1.15 ), saleDateFrom: (Date.today - (12*30)).strftime("%Y-%m-%d") , propertyIdInput: { propertyIdList: ids_list } }
    response_hash = client(:sales).call(:refine_sold_properties, message: message).body
    response_hash[:refine_sold_properties_response][:property_id_list]
  end 

  def self.recent_sales( session_token, ids_list )
    message = { session_token: session_token, propertyIdInput: { propertyIdList: ids_list }, fetchPropertyRecentSales: true , propertyRecentSalesCriteria: { pageNumber: 1 , pageSize: 10, mappingDetailsOnly: false }}
    response_hash = client(:property_search).call(:search, message: message ).body
    response_hash[:search_response][:property_search_recent_sales_result][:property_search_sales].collect{ |x| x[:property_id] }
  end

  def self.refine_otm_properties( session_token, ids_list, target_property ) 
    message = { sessionToken: session_token, bedrooms: target_property.bedrooms,  listingPriceFrom: (target_property.avm * 0.85 ), listingPriceTo: (target_property.avm * 1.15 ), listingDateFrom: (Date.today - (21)).strftime("%Y-%m-%d") , propertyIdInput: { propertyIdList: ids_list } }
    response_hash = client(:on_the_market).call(:refine_otm_properties, message: message).body
    puts "response hash"
    puts response_hash.inspect
    response_hash[:refine_otm_properties_response][:property_id_response][:property_id_list] rescue []
  end

  def self.rental_otms( session_token, ids_list , target_property )
    message = { session_token: session_token, propertyIdInput: { propertyIdList: ids_list }, fetchPropertyOTMRental: true , propertyOTMRentalCriteria: { pageNumber: 1 , pageSize: 10, mappingDetailsOnly: false }}
    response_hash = client(:property_search).call(:search, message: message ).body
    response_hash[:search_response][:property_search_otm_rental_result][:property_search_ot_ms]
  end

  def self.otm_property_summary_list( session_token, ids_list )
    message = { session_token: session_token, propertyIdInput: { propertyIdList: ids_list }}
    response_hash = client(:on_the_market).call(:get_otm_property_summary_list, message: message ).body
    response_hash[:get_otm_property_summary_list_response][:otm_summary_list]
  end


  def self.comparable_otms_valuers( session_token, rp_data_property_id )
    comparable_otms = []
    with_valid_id(rp_data_property_id) do  
      message = { sessionToken: session_token, propertyId: rp_data_property_id, fetchPropertyComparableOTMs: true }
      hash = client(:valuers).call(:get_valuers, message: message).body
      (hash[hash.keys.first][:property_comparable_ot_ms][:comparable_ot_ms] rescue [] ).each do |cot|
        comparable_otms << OpenStruct.new({ photo: (cot[:main_photo][:small_image_display_url] rescue nil), address: cot[:property_address][:address], 
          price: cot[:listed_sale_price_description], listed_date: cot[:listed_date],
           attributes: cot[:attributes], agency: cot[:selling_agency], agent: cot[:selling_agent] })
      end
    end
    comparable_otms
  end

  def self.sales_radius_search( session_token, rp_data_property_id, radius )
    with_valid_id( rp_data_property_id ) do 
      message = { sessionToken: session_token, fetchPropertySales: true, propertySalesCriteria: { soldFromDate: (Date.today - 1).iso8601 , pageNumber: 1, pageSize: 3, mappingDetailsOnly: false } ,
      searchRadiusCriteria: { propertyTypes: ["UNIT, HOUSE"], radius: radius, latitude: '-33.87185899', longitude: '151.22386797'} }
      hash = client(:property_search).call(:search, message: message ).body
    end
  end

  # A list of sold properties.
  def self.market_comparison( session_token, rp_data_property_id )
    market_comparisons = []
    with_valid_id(rp_data_property_id) do  
      message = { sessionToken: session_token, propertyId: rp_data_property_id, fetchPropertyMarketComparisons: true }
      hash = client(:valuers).call(:get_valuers, message: message).body
      hash[hash.keys.first][:property_market_comparisons][:market_comparisons].each do |mc|
        market_comparisons << OpenStruct.new({ photo: ( mc[:main_photo][:small_image_display_url] rescue nil) , 
          address: mc[:property_address][:address], 
          days_on_market: mc[:days_on_the_market], 
          price: mc[:first_ad_price],
          attributes: mc[:attributes] })
      end
    end
    market_comparisons
  end

  def self.comparable_sales( session_token, rp_data_property_id )
    comparable_sales = []
    with_valid_id(rp_data_property_id) do  
      message = { sessionToken: session_token, propertyId: rp_data_property_id, fetchPropertyComparableSales: true }
      hash = client(:valuers).call(:get_valuers, message: message).body
      hash[hash.keys.first][:property_comparable_sales][:comparable_sales].each do |cs|
        comparable_sales << OpenStruct.new({ photo: ( cs[:main_photo][:small_image_display_url] rescue nil) , 
          address: cs[:property_address][:address], 
          sale_date: cs[:last_sale_date],
          sale_method: cs[:method_of_sale], 
          price: cs[:last_sale_price],
          attributes: cs[:attributes] })
      end
    end
    comparable_sales
  end

  ##
  # Returns the On The Market history for a property.
  # 
  # Raises an ArgumentError if +rp_data_property_id+ is not provided.
  #
  def self.on_the_market_history( session_token, rp_data_property_id )
    with_valid_id(rp_data_property_id) do
      message = { sessionToken: session_token, propertyId: rp_data_property_id }
      response_hash = client(:on_the_market).call(:get_listings_for_property_id, message: message).body
      response_hash[:get_listings_for_property_id_response][:listings]
    end
  end

  ##
  # Returns the list of available services
  # 
  def self.available_services
    AVAILABLE_WSDLS.keys
  end

  def self.appraisal_data(session_token, rp_data_property_id)
    with_valid_id(rp_data_property_id) do 
      year_built = ""
      message = { sessionToken: session_token, propertyId: rp_data_property_id }  
      body = client(:property).call(:get_property_detail, message: message).body    
      body[body.keys.first][:property][:full_property_attributes].each do |full_property_attribute|
        year_built = full_property_attribute[:value] if full_property_attribute[:name] == "Year Built"
      end
      puts "poorra"
      puts body[body.keys.first][:property][:property_default_photo].inspect
      address = body[body.keys.first][:property][:property_address] 
      attributes = body[body.keys.first][:property][:property_attributes]
      OpenStruct.new( unit_number: address[:unit_designator], street_number: address[:street_designator], address: address[:address],
        street_name: address[:street_name], street_type: address[:street_extension], post_code: address[:post_code], suburb: address[:locality_name], state: address[:state_code],
        bedrooms: attributes[:bedrooms], bathrooms: attributes[:bathrooms], car_spaces: attributes[:car_spaces], land_area: attributes[:land_area],
         year_built: year_built, photo: ( body[body.keys.first][:property][:property_default_photo][:thumbnail_url] rescue nil ), id: body[body.keys.first][:property][:property_id] )
    end
  end

  private
  
  def self.client( key )
  	Savon.client(wsdl: AVAILABLE_WSDLS[key], pretty_print_xml: false)
  end

  def self.with_valid_id( param )
    raise ArgumentError if param.blank?
    yield
  end

  def self.validating_response( response_body )
    fkey = response_body.keys.first.to_sym
    puts response_body[:messages]
    puts fkey

    if response_body[:messages][:message_type] == "Error"
      raise Exception.new( "#{response_body[:messages][:message_key]} - #{response_body[:messages][:message]}" )
    else
      response_body
    end
  end




end
