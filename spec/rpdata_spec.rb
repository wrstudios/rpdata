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
        id = Rpdata.id_for_address( @session_token, "3/9 Jarnahill Drive Mount Coolum, QLD, 4573")
        expect(id).to_not be_nil
      end
    end

    describe "suggestion_list" do

      it "should get a suggestion list based on a single line search" do 
        response = Rpdata.suggestion_list( @session_token, "3/9 Jarnahill Drive Mount Coolum, QLD, 4573")
        expect( response ).to be_an_instance_of(Hash)
        puts response[:property_address_match] 
        response[:suggestions].each do | suggestion| 
          puts "#{suggestion[:property_id]} - #{suggestion[:single_line]}"
        end
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
        @rp_data_id = Rpdata.id_for_address(@session_token, '3/9 Jarnahill Drive Mount Coolum, QLD, 4573' )
      end

      describe "property_history" do 
        it "should return a list of sale history" do 
          response = Rpdata.property_history( @session_token, @rp_data_id )
          expect(response).to be_an_instance_of(OpenStruct)
        end
      end

      describe "comparable otms" do 

        it "should return the comparable On The Market properties" do 
          response = Rpdata.comparable_otms_valuers( @session_token, @rp_data_id )
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

      describe "#fetch_property" do 
        it "should work" do 
          response = Rpdata.fetch_property( @session_token, @rp_data_id )
          expect(response).to be_an_instance_of(OpenStruct)
        end
      end

      describe "#property_ids_by_nearest_suburb" do 
        it "should work" do 
          response = Rpdata.property_ids_by_nearest_suburb( @session_token, @rp_data_id )        
          expect(response).to be_an_instance_of(Array)
        end
      end

      describe "#refine_sold_properties" do 
        it 'should work' do 
          property = Rpdata.fetch_property(@session_token, @rp_data_id)
          nearest_properties_ids = Rpdata.property_ids_by_nearest_suburb( @session_token, property.property_id ).collect(&:property_id)
          puts "inspecting..."
          puts property.inspect
          response = Rpdata.refine_sold_properties( @session_token, nearest_properties_ids, property )
          expect(response).to be_an_instance_of(Array)
          resp = Rpdata.property_summary( @session_token , response.first )
          puts resp
        end 
      end

      describe "#recent_sales" do 
        it 'should work' do 
          nearest_properties_ids = Rpdata.property_ids_by_nearest_suburb( @session_token, @rp_data_id ).collect(&:property_id)
          response = Rpdata.recent_sales( @session_token, nearest_properties_ids )
          expect(response).to be_an_instance_of(Array)
          puts response
        end        
      end

      describe "#refine_otm_properties(sales)" do
        it 'should work' do 
          property = Rpdata.fetch_property(@session_token, @rp_data_id)
          nearest_properties_ids = Rpdata.property_ids_by_nearest_suburb( @session_token, property.property_id ).collect(&:property_id)
          response = Rpdata.refine_otm_properties( @session_token, nearest_properties_ids, property )
          puts Rpdata.otm_property_summary_list( @session_token, response )
        end
      end

      describe "#rental_otms" do 
        it 'should work' do 
          property = Rpdata.fetch_property(@session_token, @rp_data_id)
          nearest_properties_ids = Rpdata.property_ids_by_nearest_suburb( @session_token, property.property_id ).collect(&:property_id)
          response = Rpdata.rental_otms( @session_token, nearest_properties_ids, property )
          puts response
        end
      end

      describe "#sales_radius_search" do 
        it "should work" do 
          response = Rpdata.sales_radius_search(@session_token, @rp_data_id, 5)
          expect(response).to be_an_instance_of(Hash)
        end
      end

      describe "appraisal_data" do 

        it "should return an OPenStruct with the relevant appraisal data" do 
          response = Rpdata.appraisal_data( @session_token, @rp_data_id )
          puts response
          expect(response).to be_an_instance_of(OpenStruct)
          puts "**************************************"
          puts "#{response.inspect}"
          puts "**************************************"
        end

      end

      describe "property_details" do 
        
        it "should return a response object"  do 
          response = Rpdata.property_details( @session_token, @rp_data_id )
          puts response.sale_history.inspect
          expect( response ).to be_an_instance_of(OpenStruct)
        end

        it "should raise an expection if an id is not provided" do 
          expect { Rpdata.property_details( @session_token , nil) }.to raise_error(ArgumentError)
        end 

      end

      describe "property_summary" do 
        
        it "should return a response object" do 
         response = Rpdata.property_summary( @session_token, @rp_data_id )
         expect( response ).to be_an_instance_of(Hash)
        end

        it "should raise an exception if an id is not provided" do
          expect{ Rpdata.property_summary(@session_token, nil) }.to raise_error(ArgumentError)
        end

      end

      describe "sale_detail" do 
        
        it "should return a response object" do 
          response = Rpdata.sale_detail( @session_token, @rp_data_id )
          puts response
          expect( response ).to be_a(OpenStruct)
        end

        it "should raise an exception if an id is not provided" do 
          expect{ Rpdata.sale_detail(@session_token, nil)}.to raise_error(ArgumentError)
        end 

      end

      describe "on_the_market_history" do 

        it "should get the On The Market history" do 
          response = Rpdata.on_the_market_history( @session_token, @rp_data_id )
          expect( response ).to be_a(Array)
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