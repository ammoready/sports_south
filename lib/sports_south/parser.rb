module SportsSouth
  class Parser

    CATALOG_CODES = {
      'S' => :special,
      'C' => :closeout,
      'F' => :flyer,
      'B' => :buyers_special,
      'N' => :net_price,
    }

    ITEM_TYPES = {
      '1' => :handgun,
      '2' => :long_gun,
      '3' => :accessory,
      '4' => :ammunition,
      '5' => :optics,
      '6' => :archery,
      '7' => :reloading,
    }

    attr_reader :file

    def initialize(file)
      @file = file
    end

    def self.chunk(file, &block)
      new(file).chunk(&block)
    end

    def chunk(&block)
      File.open(@file) do |file|
        Nokogiri::XML::Reader.from_io(file).each do |node|
          if node.name == 'Table' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
            yield(self.process_table_node(Nokogiri::XML(node.outer_xml)))
          end
        end
      end
    end

    protected

    def process_table_node(table_node)
      {
        item_number:              self.content_for(table_node, 'ITEMNO'),
        description:              content_for(table_node, 'IDESC'),
        manufacturer_sequence:    content_for(table_node, 'IMFSEQ'),
        manufacturer_number:      content_for(table_node, 'IMFGNO'),
        catalog_sequence:         content_for(table_node, 'CSEQ'),
        item_type:                ITEM_TYPES[content_for(table_node, 'ITYPE')],
        short_description:        content_for(table_node, 'SHDESC'),
        unit_of_measure:          content_for(table_node, 'UOM'),
        catalog_price:            content_for(table_node, 'PRC1'),
        customer_price:           content_for(table_node, 'CPRC'),
        quantity_on_hand:         content_for(table_node, 'QTYOH'),
        weight_per_box:           content_for(table_node, 'WTPBX'),
        upc:                      content_for(table_node, 'ITUPC'),
        manufacturer_item_number: content_for(table_node, 'MFGINO'),
        scan_name_1:              content_for(table_node, 'SCNAM1'),
        scan_name_2:              content_for(table_node, 'SCNAM2'),
        catalog_code:             CATALOG_CODES[content_for(table_node, 'CATCD')],
        mapp_price_code:          content_for(table_node, 'MFPRTYP'),
        mapp_price:               content_for(table_node, 'MFPRC'),
        category_id:              content_for(table_node, 'CATID'),
        text_reference_number:    content_for(table_node, 'TXTREF'),
        picture_reference_number: content_for(table_node, 'PICREF'),
        brand_id:                 content_for(table_node, 'ITBRDNO'),
        item_model_number:        content_for(table_node, 'IMODEL'),
        item_purpose:             content_for(table_node, 'IPURPOSE'),
        series_description:       content_for(table_node, 'SERIES'),
        item_length:              content_for(table_node, 'LENGTH'),
        item_height:              content_for(table_node, 'HEIGHT'),
        item_width:               content_for(table_node, 'WIDTH'),
        item_ships_hazmat_air:    content_for(table_node, 'HAZAIR'),
        item_ships_hazmat_ground: content_for(table_node, 'HAZGRND'),
        date_of_last_change:      content_for(table_node, 'CHGDTE'),
        date_added:               content_for(table_node, 'CHGDTE'),
        attribute_1:              content_for(table_node, 'ITATR1'),
        attribute_2:              content_for(table_node, 'ITATR2'),
        attribute_3:              content_for(table_node, 'ITATR3'),
        attribute_4:              content_for(table_node, 'ITATR4'),
        attribute_5:              content_for(table_node, 'ITATR5'),
        attribute_6:              content_for(table_node, 'ITATR6'),
        attribute_7:              content_for(table_node, 'ITATR7'),
        attribute_8:              content_for(table_node, 'ITATR8'),
        attribute_9:              content_for(table_node, 'ITATR9'),
        attribute_10:             content_for(table_node, 'ITATR0'),
        attribute_11:             content_for(table_node, 'ITATR11'),
        attribute_12:             content_for(table_node, 'ITATR12'),
        attribute_13:             content_for(table_node, 'ITATR13'),
        attribute_14:             content_for(table_node, 'ITATR14'),
        attribute_15:             content_for(table_node, 'ITATR15'),
        attribute_16:             content_for(table_node, 'ITATR16'),
        attribute_17:             content_for(table_node, 'ITATR17'),
        attribute_18:             content_for(table_node, 'ITATR18'),
        attribute_19:             content_for(table_node, 'ITATR19'),
        attribute_20:             content_for(table_node, 'ITATR20')
      }
    end

    def content_for(table_node, field)
      node = table_node.css(field).first
      node.nil? ? nil : node.content.strip
    end

  end
end
