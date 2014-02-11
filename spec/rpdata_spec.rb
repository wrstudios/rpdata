require 'spec_helper'


describe Rpdata do 

 

  it "should have a list of available services" do 
    expect( Rpdata.respond_to?(:available_services)).to be(true)
    expect( Rpdata.available_services).to be_an_instance_of(Array)
  end

  describe "generate_token" do 

    it "should generate a token with the user credentials" do 
      expect( Rpdata.generate_token( 'bsguser.iproperty', 'x5yGCV85', '500998' , '43376848' ) )
    end

    it "should raise an exception if token can't be gerated" do 
      expect{ Rpdata.generate_token( 'bsguser.iproperty', 'wrong',  '500998' ,  '43376848' ) }.to raise_error
    end

  end


  describe "having an auth token" do 
    
    before(:each) do 
      puts "executing the token generation..."
      @session_token = Rpdata.generate_token( 'bsguser.iproperty', 'x5yGCV85', '500998' , '43376848' )
    end

    describe "id_for_address" do 

      it "should return the first suggestion occurance for an address" do 
        id = Rpdata.id_for_address( @session_token, "380 David Low Way")
        expect(id).to_not be_nil
      end
    end

    
    describe "suggestion_list" do

      it "should get a suggestion list based on a single line search" do 
        response = Rpdata.suggestion_list( @session_token, "380 David Low Way").body
        expect( response ).to be_an_instance_of(Hash)
        expect(response.keys).to include(:get_property_match_response)
      end

      it "should raise ArgumentError if a search params is invalid" do 
        expect{ Rpdata.suggestion_list(@session_token, nil )}.to raise_error(ArgumentError)
      end

    end

    describe "based on a postcode" do 
      describe "#suburb_stats" do 
        it "should return the suburbs statistics" do 
          response = Rpdata.suburb_stats( @session_token, "Sunshine Beach", "4567", "QLD")
          expect(response).to be_an_instance_of(OpenStruct)
        end
      end
    end

    describe "based on a rpdata property id" do 
      
      before do 
        #@rp_data_id = Rpdata.suggestion_list( @session_token, "380 David Low Way" ).body[:get_property_match_response][:suggestions].first[:property_id] 
        #@rp_data_id = '6168318'
        @rp_data_id = Rpdata.id_for_address(@session_token, '7 Duke Street, Sunshine Beach QLD')
      end

      describe "property_history" do 
        it "should return a list of sale history" do 
          response = Rpdata.property_history( @session_token, @rp_data_id )
          expect(response).to be_an_instance_of(OpenStruct)

        end
      end

      describe "comparable otms" do 

        it "should return the comparable On The Market properties" do 
          response = Rpdata.comparable_otms( @session_token, @rp_data_id )
          expect(response).to be_an_instance_of(Array)
        end

      end

      describe "market comparison" do 

        it "should return a list of sold properties for market comparison" do 
          response = Rpdata.market_comparison( @session_token, @rp_data_id )
          expect(response).to be_an_instance_of(Array)
        end
        
      end

      describe "property_photos" do 

        it "should return a list of photos for a given property" do 
          response = Rpdata.property_photos( @session_token, @rp_data_id )
          expect(response).to be_an_instance_of(Array)
        end

        it "should raise an exception if an id is not provided" do
          expect{ Rpdata.property_photos( @session_token, nil ) }.to raise_error
        end

      end

      describe "appraisal_data" do 

        it "should return an OPenStruct with the relevant appraisal data" do 
          response = Rpdata.appraisal_data( @session_token, @rp_data_id )
          expect(response).to be_an_instance_of(OpenStruct)
          puts "**************************************"
          puts "#{response.inspect}"
          puts "**************************************"
        end

      end

      describe "property_details" do 
        
        it "should return a response object"  do 
          response = Rpdata.property_details( @session_token, @rp_data_id )
          puts "inspecting the thing...."
          puts response.sale_history.inspect
          expect( response ).to be_an_instance_of(OpenStruct)
        end

        it "should raise an expection if an id is not provided" do 
          expect { Rpdata.property_details( @session_token , nil) }.to raise_error(ArgumentError)
        end

      end

      describe "property_summary" do 
        
        it "should return a response object" do 
         response = Rpdata.property_summary( @session_token, @rp_data_id ).body
         expect( response.keys ).to include(:get_property_summary_response)
        end

        it "should raise an exception if an id is not provided" do
          expect{ Rpdata.property_summary(@session_token, nil) }.to raise_error(ArgumentError)
        end

      end

      describe "sale_history" do 
        
        it "should return a response object" do 
          response = Rpdata.sale_history( @session_token, @rp_data_id ).body
          expect( response.keys ).to include(:get_sale_detail_response)
        end

        it "should raise an exception if an id is not provided" do 
          expect{ Rpdata.sale_history(@session_token, nil)}.to raise_error(ArgumentError)
        end 

      end

      describe "on_the_market_history" do 

        it "should get the On The Market history" do 
          response = Rpdata.on_the_market_history( @session_token, @rp_data_id ).body
          expect( response.keys ).to include(:get_listings_for_property_id_response)
        end

        it "should raise an exception if an id is not provided" do 
          expect{ Rpdata.on_the_market_history(@session_token, nil)}.to raise_error(ArgumentError)
        end

      end

    end

  end

  # it "should get the recent sales for the suburb"

  
  it "should get a session token"



  


end