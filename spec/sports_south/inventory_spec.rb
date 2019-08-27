require 'spec_helper'

describe SportsSouth::Inventory do

  let(:credentials) { { username: 'usr', password: 'pa$$' } }

  before do
    tempfile = Tempfile.new('incremental_onhand_update')
    FileUtils.copy_file(FixtureHelper.get_fixture('incremental_onhand_update.xml').path, tempfile.path)
    allow_any_instance_of(SportsSouth::Inventory).to receive(:download_to_tempfile) { tempfile }
  end

  describe '.all' do
    it 'yields all items as array' do
      items = SportsSouth::Inventory.all(credentials)

      items.each_with_index do |item, index|
        case index
        when 0
          expect(item[:item_identifier]).to eq('50001')
          expect(item[:quantity]).to        eq(25)
          expect(item[:price]).to           eq('11.89')
        when 1
          expect(item[:item_identifier]).to eq('50002')
          expect(item[:quantity]).to        eq(5)
          expect(item[:price]).to           eq('110.99')
        when 49
          expect(item[:item_identifier]).to eq('50050')
          expect(item[:quantity]).to        eq(10)
          expect(item[:price]).to           eq('310.62')
        end
      end

      expect(items.count).to eq(50)
    end
  end

  describe '.quantity' do
    it 'yields all items as array' do
      items = SportsSouth::Inventory.quantity(credentials)

      expect(items.count).to eq(50)
    end
  end

end
