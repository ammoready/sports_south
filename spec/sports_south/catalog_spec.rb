require 'spec_helper'

describe SportsSouth::Catalog do

  let(:credentials) { { username: 'usr', password: 'pa$$' } }

  before do
    allow(SportsSouth::Category).to receive(:all).with(credentials) do
      @categories_file ||= FixtureHelper.get_fixture('categories.json')
      @categories      ||= JSON.parse(@categories_file.read, symbolize_names: true)
    end

    allow(SportsSouth::Brand).to receive(:all).with(credentials) do
      @brands_file ||= FixtureHelper.get_fixture('brands.json')
      @brands      ||= JSON.parse(@brands_file.read, symbolize_names: true)
    end

    tempfile = Tempfile.new('daily_item_update')
    FileUtils.copy_file(FixtureHelper.get_fixture('daily_item_update.xml').path, tempfile.path)
    allow_any_instance_of(SportsSouth::Catalog).to receive(:download_to_tempfile) { tempfile }
  end

  describe '.all' do
    it 'returns all items in an array' do
      items = SportsSouth::Catalog.all(credentials)

      items.each_with_index do |item, index|
        case index
        when 0
          expect(item[:name]).to            eq('Reginald Ammo-1')
          expect(item[:upc]).to             eq('123000000001')
          expect(item[:item_identifier]).to eq('50001')
          expect(item[:price]).to           eq('11.89')
          expect(item[:quantity]).to        eq(25)
          expect(item[:category]).to        eq('Cool Category')
          expect(item[:brand]).to           eq('Brand 1')
          expect(item[:caliber]).to         eq(nil)
        when 1
          expect(item[:name]).to            eq('MMM Handgun-1')
          expect(item[:upc]).to             eq('123000000002')
          expect(item[:item_identifier]).to eq('50002')
          expect(item[:price]).to           eq('110.99')
          expect(item[:quantity]).to        eq(25)
          expect(item[:category]).to        eq('Cool Category')
          expect(item[:brand]).to           eq('Brand 2')
          expect(item[:caliber]).to         eq('9MM')
        when 55
          expect(item[:name]).to            eq('Model 56 Handgun-8')
          expect(item[:upc]).to             eq('123000000056')
          expect(item[:item_identifier]).to eq('50056')
          expect(item[:price]).to           eq('422.62')
          expect(item[:quantity]).to        eq(10)
          expect(item[:category]).to        eq('Marshmallow Guns')
          expect(item[:brand]).to           eq('Brand 3')
          expect(item[:caliber]).to         eq('380')
          expect(item[:weight]).to          eq('2.3')
        end
      end

      expect(items.count).to eq(56)
    end
  end

end
