require 'spec_helper'


describe Rpdata do 

  it "should have a list of available services" do 
    expect( Rpdata.respond_to?(:available_services)).to be(true)
    expect( Rpdata.available_services).to be_an_instance_of(Array)
  end

  it "should get property matches based on a single line search" do 
    session_token = "49998-fb7f5f1266184b7265901551974dd4f1"

    response = Rpdata.get_property_match( session_token, "6/380 David Low Way").body
    puts "keys"
    puts response.keys
    expect( response ).to be_an_instance_of(Hash)
    expect(response[:get_property_match_response].has_key?(:property_address_match)).to eql( true )
    
    

  end

  
  it "should get a session token"



  


end