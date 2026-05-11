require 'spec_helper'

describe SportsSouth::Catalog do

  API_BASE = 'http://webservices.theshootingwarehouse.com/smart/inventory.asmx'

  let(:credentials) { { username: 'usr', password: 'pa$$' } }

  before do
    allow(SportsSouth::Category).to receive(:all) do
      @categories_file ||= FixtureHelper.get_fixture('categories.json')
      @categories      ||= JSON.parse(@categories_file.read, symbolize_names: true)
    end

    allow(SportsSouth::Brand).to receive(:all) do
      @brands_file ||= FixtureHelper.get_fixture('brands.json')
      @brands      ||= JSON.parse(@brands_file.read, symbolize_names: true)
    end
  end

  describe '.all' do
    context 'with a single page of results' do
      before do
        stub_request(:post, "#{API_BASE}/DailyItemUpdate").
          to_return(status: 200, body: FixtureHelper.get_fixture('daily_item_update.xml').read)

        stub_request(:post, "#{API_BASE}/DailyItemCount").
          to_return(status: 200, body: '<int xmlns="http://webservices.theshootingwarehouse.com/smart/Inventory.asmx">56</int>')
      end

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

    context 'when daily_item_count > 1000' do
      let(:page1_xml) do
        <<~XML
          <string xmlns="http://webservices.theshootingwarehouse.com/smart/Inventory.asmx">
            <NewDataSet>
              <Table>
                <ITEMNO>10001</ITEMNO><ITUPC>000000010001</ITUPC><CPRC>9.99</CPRC>
                <QTYOH>5</QTYOH><CATID>5</CATID><ITBRDNO>1</ITBRDNO>
                <IMODEL>Model A</IMODEL><MFGINO>SKU-A</MFGINO><SERIES>S1</SERIES>
                <ITYPE>3</ITYPE><WTPBX>1.0</WTPBX><MFPRC>0</MFPRC><UOM>BX</UOM>
                <SHDESC>Item A</SHDESC>
              </Table>
              <Table>
                <ITEMNO>10002</ITEMNO><ITUPC>000000010002</ITUPC><CPRC>19.99</CPRC>
                <QTYOH>10</QTYOH><CATID>5</CATID><ITBRDNO>2</ITBRDNO>
                <IMODEL>Model B</IMODEL><MFGINO>SKU-B</MFGINO><SERIES>S2</SERIES>
                <ITYPE>3</ITYPE><WTPBX>2.0</WTPBX><MFPRC>0</MFPRC><UOM>BX</UOM>
                <SHDESC>Item B</SHDESC>
              </Table>
            </NewDataSet>
          </string>
        XML
      end

      let(:page2_xml) do
        <<~XML
          <string xmlns="http://webservices.theshootingwarehouse.com/smart/Inventory.asmx">
            <NewDataSet>
              <Table>
                <ITEMNO>10003</ITEMNO><ITUPC>000000010003</ITUPC><CPRC>29.99</CPRC>
                <QTYOH>3</QTYOH><CATID>5</CATID><ITBRDNO>3</ITBRDNO>
                <IMODEL>Model C</IMODEL><MFGINO>SKU-C</MFGINO><SERIES>S3</SERIES>
                <ITYPE>3</ITYPE><WTPBX>3.0</WTPBX><MFPRC>0</MFPRC><UOM>BX</UOM>
                <SHDESC>Item C</SHDESC>
              </Table>
            </NewDataSet>
          </string>
        XML
      end

      before do
        stub_request(:post, "#{API_BASE}/DailyItemCount").
          to_return(status: 200, body: '<int xmlns="http://webservices.theshootingwarehouse.com/smart/Inventory.asmx">1200</int>')

        stub_request(:post, "#{API_BASE}/DailyItemUpdate").
          with(body: hash_including('LastItem' => '0')).
          to_return(status: 200, body: page1_xml)

        stub_request(:post, "#{API_BASE}/DailyItemUpdate").
          with(body: hash_including('LastItem' => '10002')).
          to_return(status: 200, body: page2_xml)
      end

      it 'fetches all pages and concatenates results' do
        items = SportsSouth::Catalog.all(credentials.merge(last_item: 0))

        expect(items.count).to eq(3)
        expect(items[0][:item_identifier]).to eq('10001')
        expect(items[1][:item_identifier]).to eq('10002')
        expect(items[2][:item_identifier]).to eq('10003')
      end
    end

    context 'with full_product: true' do
      let(:item_xml) do
        <<~XML
          <string xmlns="http://webservices.theshootingwarehouse.com/smart/Inventory.asmx">
            <NewDataSet>
              <Table>
                <ITEMNO>20001</ITEMNO><ITUPC>000000020001</ITUPC><CPRC>49.99</CPRC>
                <QTYOH>7</QTYOH><CATID>5</CATID><ITBRDNO>1</ITBRDNO>
                <IMODEL>Full Model</IMODEL><MFGINO>FM-1</MFGINO><SERIES>FS</SERIES>
                <ITYPE>3</ITYPE><WTPBX>1.5</WTPBX><MFPRC>0</MFPRC><UOM>BX</UOM>
                <SHDESC>Full Item</SHDESC>
              </Table>
            </NewDataSet>
          </string>
        XML
      end

      before do
        stub_request(:post, "#{API_BASE}/DailyItemUpdate").
          to_return(status: 200, body: item_xml)

        stub_request(:post, "#{API_BASE}/DailyItemCount").
          to_return(status: 200, body: '<int xmlns="http://webservices.theshootingwarehouse.com/smart/Inventory.asmx">1</int>')

        stub_request(:post, "#{API_BASE}/GetText").
          to_return(status: 200, body: '<string xmlns="http://webservices.theshootingwarehouse.com/smart/Inventory.asmx"><CATALOGTEXT>A detailed product description</CATALOGTEXT></string>')
      end

      it 'fetches long descriptions for all items' do
        items = SportsSouth::Catalog.all(credentials.merge(full_product: true))

        expect(items.count).to eq(1)
        expect(items.first[:long_description]).to eq('A detailed product description')
      end
    end

    context 'with upcs_to_not_process' do
      before do
        stub_request(:post, "#{API_BASE}/DailyItemUpdate").
          to_return(status: 200, body: FixtureHelper.get_fixture('daily_item_update.xml').read)

        stub_request(:post, "#{API_BASE}/DailyItemCount").
          to_return(status: 200, body: '<int xmlns="http://webservices.theshootingwarehouse.com/smart/Inventory.asmx">56</int>')
      end

      it 'excludes items whose UPC is present in the lookup hash' do
        skip_upcs = Set['123000000001', '123000000056']
        items = SportsSouth::Catalog.all(credentials.merge(upcs_to_not_process: skip_upcs))

        expect(items.count).to eq(54)
        expect(items.map { |i| i[:upc] }).not_to include('123000000001', '123000000056')
      end
    end
  end

  describe '#map_features' do
    let(:catalog) { SportsSouth::Catalog.new(credentials) }

    context 'when category lookup returns nil (attributes is an empty hash)' do
      let(:node_no_itatr) do
        Nokogiri::XML.parse('<Table></Table>').css('Table')
      end

      let(:node_with_itatr20) do
        Nokogiri::XML.parse('<Table><ITATR20>SomeValue</ITATR20></Table>').css('Table')
      end

      let(:node_with_itatr1_only) do
        Nokogiri::XML.parse('<Table><ITATR1>Pistol</ITATR1></Table>').css('Table')
      end

      it 'returns an empty hash when no ITATR values are present' do
        result = catalog.send(:map_features, {}, node_no_itatr)
        expect(result).to eq({})
      end

      it 'does not raise an error when ITATR20 has a value' do
        expect { catalog.send(:map_features, {}, node_with_itatr20) }.not_to raise_error
      end

      it 'returns a hash without nil keys when ITATR20 has a value' do
        result = catalog.send(:map_features, {}, node_with_itatr20)
        expect(result.keys).not_to include(nil)
      end

      it 'returns an empty hash when only earlier ITATR fields have values' do
        result = catalog.send(:map_features, {}, node_with_itatr1_only)
        expect(result).to eq({})
      end
    end
  end

end
