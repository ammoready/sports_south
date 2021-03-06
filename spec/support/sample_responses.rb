module SampleResponses

  def add_header_response
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <int xmlns="http://webservices.theshootingwarehouse.com/smart/Orders">1200099</int>
    XML
  end

  def sample_list_new_text
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <string xmlns="http://webservices.theshootingwarehouse.com/smart/Inventory.asmx"><NewDataSet>
        <Table>
          <ITEMNO>38317</ITEMNO>
          <TEXT>Kahr Arms S9 features a black polymer frame with accessory rail.</TEXT>
        </Table>
        <Table>
          <ITEMNO>39303</ITEMNO>
          <TEXT>The Steyr Mannlicher Pro Hunter offers a modern compliment to other traditional platforms.</TEXT>
        </Table>
        <Table>
          <ITEMNO>33625</ITEMNO>
          <TEXT />
        </Table>
      </NewDataSet></string>
    XML
  end

end
