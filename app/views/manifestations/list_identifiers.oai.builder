xml.instruct! :xml, :version=>"1.0"
xml.tag! "OAI-PMH", :xmlns => "http://www.openarchives.org/OAI/2.0/",
  "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
  "xsi:schemaLocation" => "http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd" do
  xml.responseDate Time.zone.now.utc.iso8601
  xml.request manifestations_url(:format => :oai), :verb => "ListIdentifiers", :metadataPrefix => "oai_dc"
  xml.ListIdentifiers do
    @manifestations.each do |manifestation|
      xml.header do
        xml.identifier manifestation_url(manifestation)
        xml.datestamp manifestation.updated_at.utc.iso8601
        xml.setSpec manifestation.series_statement.id if manifestation.series_statement
      end
    end
  end
end
