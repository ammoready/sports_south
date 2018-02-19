require 'spec_helper'

describe SportsSouth::Order do

  it 'has a API_URL constant' do
    expect(SportsSouth::Order::API_URL).not_to be_nil
  end

  it 'has a SHIP_VIA constant' do
    expect(SportsSouth::Order::SHIP_VIA).not_to be_nil
  end

  describe '#initialize' do
    let(:order) { SportsSouth::Order.new(username: "bob", password: "secret", customer_number: "10001", source: "ruby-gem") }

    it { expect(order).to respond_to(:order_number) }
  end

  describe "#add_header" do
    let(:order) { SportsSouth::Order.new(username: "bob", password: "secret", customer_number: "10001", source: "ruby-gem") }
    let(:params) do
      {
        purchase_order: "1000",
        sales_message:  %q(Order via AmmoReady.com),
        shipping: {
          name: "Fake name",
          attn: "Transferee - Fake Transferee",
          address_one: "123 Bob Ln.",
          address_two: "",
          city:        "Greenville",
          state:       "SC",
          zip:         "29601",
          phone:       "8009915555",
        }
      }
    end

    before do
      stub_request(:post, "http://webservices.theshootingwarehouse.com/smart/orders.asmx/AddHeader").
        with(body: {
          "AdultSignature" => "false",
          "CustomerNumber" => "bob",
          "CustomerOrderNumber" => "1000",
          "Insurance" => "false",
          "PO" => "1000",
          "Password" => "secret",
          "SalesMessage" => "Order via AmmoReady.com",
          "ShipToAddr1" => "123 Bob Ln.",
          "ShipToAddr2" => "",
          "ShipToAttn" => "Transferee - Fake Transferee",
          "ShipToCity" => "Greenville",
          "ShipToName" => "Fake name",
          "ShipToPhone" => "8009915555",
          "ShipToState" => "SC",
          "ShipToZip" => "29601",
          "ShipVia" => "",
          "Signature" => "false",
          "Source" => "ammor",
          "UserName" => "bob"
        }, headers: {
          'Accept' => '*/*',
          'Content-Type' => 'application/x-www-form-urlencoded', 
          'User-Agent' => "sports_south rubygems.org/gems/sports_south v(#{SportsSouth::VERSION})"
        }).to_return(status: 200, body: add_header_response, headers: {})
      order.add_header(params)
    end

    it { expect(order.order_number).to eq('1200099') }
  end

end
