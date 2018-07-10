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

    allow_any_instance_of(Net::HTTP).to receive(:request) do
      @file     ||= FixtureHelper.get_fixture('daily_item_update.xml')
      @response ||= instance_double('Net::HTTPResponse', body: @file.read)
    end
  end

  describe '.all' do
    it 'yields each and every item' do
      count = 0
      SportsSouth::Catalog.all(credentials) do |item|
        count += 1
      end

      expect(count).to eq(56)
    end
  end

end