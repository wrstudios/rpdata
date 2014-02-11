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
  	client(:property_search).call(:get_property_match, message: message)
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
    id = suggestion_list(session_token, suggestion_string).body[:get_property_match_response][:property_address_match][:property_id] rescue nil
    id ||= suggestion_list(session_token, suggestion_string).body[:get_property_match_response][:suggestions].first[:property_id] 
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
      client(:property).call(:get_property_summary, message: message)    
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
      puts "property..."
      
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

      puts "market history as rental"
      puts property_details.market_rental_history.first.inspect
      property_details
    end
  end

  ##
  # Returns the sale history for a property.
  # 
  # Raises an ArgumentError if +rp_data_property_id+ is not provided.
  #
  def self.sale_history( session_token, rp_data_property_id )
    with_valid_id(rp_data_property_id) do  
      message = { sessionToken: session_token, propertyId: rp_data_property_id }
      client(:sales).call(:get_sale_detail, message: message)
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

  def self.comparable_otms( session_token, rp_data_property_id )
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
      client(:on_the_market).call(:get_listings_for_property_id, message: message)
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
      address = body[body.keys.first][:property][:property_address] 
      attributes = body[body.keys.first][:property][:property_attributes]
      OpenStruct.new( unit_number: address[:unit_designator], street_number: address[:street_designator], address: address[:address],
        street_name: address[:street_name], street_type: address[:street_extension], post_code: address[:post_code], suburb: address[:locality_name], state: address[:state_code],
        bedrooms: attributes[:bedrooms], bathrooms: attributes[:bathrooms], car_spaces: attributes[:car_spaces], land_area: attributes[:land_area],
         year_built: year_built, photo: body[body.keys.first][:property][:property_default_photo][:thumbnail_url], id: body[body.keys.first][:property][:property_id] )
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




end
