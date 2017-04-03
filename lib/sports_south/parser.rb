module SportsSouth
  class Parser

    attr_reader :file

    def initialize(file)
      @file = file
    end

    def self.parse(file, node_name, &block)
      new(file).parse(node_name, &block)
    end

    def parse(node_name, &block)
      File.open(@file) do |file|
        Nokogiri::XML::Reader.from_io(file).each do |node|
          if node.name == node_name and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
            yield(Nokogiri::XML(node.outer_xml))
          end
        end
      end
    end

  end
end
