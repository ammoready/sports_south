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

    # it { pp order.add_header(params) }
  end

end
