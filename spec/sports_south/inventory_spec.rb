require 'spec_helper'

describe SportsSouth::Inventory do

  let(:credentials) { { username: 'usr', password: 'pa$$' } }

  before do
    allow_any_instance_of(Net::HTTP).to receive(:request) do
      @file     ||= FixtureHelper.get_fixture('incremental_onhand_update.xml')
      @response ||= instance_double('Net::HTTPResponse', body: @file.read)
    end
  end

  describe '.all' do
    it 'yields each and every item' do
      count = 0
      SportsSouth::Inventory.all(credentials) do |item|
        count += 1
      end

      expect(count).to eq(50)
    end
  end

  describe '.quantity' do
    it 'yields each and every item' do
      count = 0
      SportsSouth::Inventory.quantity(credentials) do |item|
        count += 1
      end

      expect(count).to eq(50)
    end
  end

end
