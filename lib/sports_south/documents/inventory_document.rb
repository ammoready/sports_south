class InventoryDocument < Nokogiri::XML::SAX::Document

  def initialize
    @current_node = nil # Keep track of the current node we are interested in
    @inside_node  = false # Keep track whether we are inside item node
    @item_data    = Hash.new # Store item data
  end

  def start_element(name, attrs = [])
    if name == 'Table'
      @inside_node  = true
    else
      if @inside_node && self.is_node_we_care_about?(name)
        @current_node = name
      end
    end
  end

  # signals text data, it may be called several times for one node
  def characters(string)
    # TODO-david
    puts string

    if @current_node
      @item_data[@current_node] += string
    end
  end

  def end_element(name)
    if name == 'Table'
      @inside_node = false
      # TODO-david probably return it here somehow......
      # clear item hash
      @item_data.clear
    else
      if @inside_node && @current_node
        @current_node = nil # finished with current node
      end
    end
  end

  protected

  def self.is_node_we_care_about?(name)
    # switch case to check for node we care about
    # see inventory self.all
    # TODO-david
  end

end
