require 'spec_helper'

describe SportsSouth::Inventory do

  describe '.list_new_text' do
    let(:options) do
      {
        username: 'usr',
        password: 'pa$$',
        source: 'ammor',
        customer_number: '1234',
        since: '06/19/2017'
      }
    end
    let(:expectation) do
      [
        {
          item_number: "38317",
          text: "Kahr Arms S9 features a black polymer frame with accessory rail."
        }, {
          item_number: "39303",
          text: "The Steyr Mannlicher Pro Hunter offers a modern compliment to other traditional platforms."
        }, {
          item_number: "33625", 
          text: ""
        }
      ]
    end

    before do
      stub_request(:post, "http://webservices.theshootingwarehouse.com/smart/inventory.asmx/ListNewText").
        with(body: {
            "CustomerNumber" => "1234",
            "DateFrom" => "06/19/2017",
            "Password" => "pa$$",
            "Source"   => "ammor",
            "UserName" => "usr"
          }, headers: {
            'Content-Type' => 'application/x-www-form-urlencoded',
            'User-Agent'   => "sports_south rubygems.org/gems/sports_south v(#{SportsSouth::VERSION})"
          }).
        to_return(status: 200, body: sample_list_new_text)

      @response = SportsSouth::Inventory.list_new_text(options)
    end

    xit { expect(@response).to eq(expectation) }
  end

end
