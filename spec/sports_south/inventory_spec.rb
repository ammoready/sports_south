require 'spec_helper'

describe SportsSouth::Inventory do

  let(:credentials) { { username: 'usr', password: 'pa$$' } }

  before do
    tempfile = Tempfile.new('incremental_onhand_update')
    FileUtils.copy_file(FixtureHelper.get_fixture('incremental_onhand_update.xml').path, tempfile.path)
    allow_any_instance_of(SportsSouth::Inventory).to receive(:download_to_tempfile) { tempfile }
  end

  describe '.all' do
    it 'yields each and every item' do
      count = 0
      SportsSouth::Inventory.all(credentials) do |item|
        count += 1
        case count
        when 1
          expect(item[:item_identifier]).to eq('50001')
          expect(item[:quantity]).to        eq(25)
          expect(item[:price]).to           eq('11.89')
        when 2
          expect(item[:item_identifier]).to eq('50002')
          expect(item[:quantity]).to        eq(5)
          expect(item[:price]).to           eq('110.99')
        when 50
          expect(item[:item_identifier]).to eq('50050')
          expect(item[:quantity]).to        eq(10)
          expect(item[:price]).to           eq('310.62')
        end
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
