xml.instruct! :xml, :version=>"1.0" 
xml.rdf(:RDF,
        'xmlns'  => "http://purl.org/rss/1.0/",
        'xmlns:rdf'  => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
        'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
        'xmlns:foaf' => "http://xmlns.com/foaf/0.1/",
        'xmlns:prism' => "http://prismstandard.org/namespaces/basic/2.0/",
        'xmlns:rdfs' =>"http://www.w3.org/2000/01/rdf-schema#"){
  xml.channel("rdf:about" => manifestations_url(:params => params.merge(:format => 'rdf'))){
    xml.title t('manifestation.query_search_result', :query => @query, :library_group_name => @library_group.display_name.localize)
    xml.link "#{request.protocol}#{request.host_with_port}#{url_for(params.merge(:format => nil))}"
    xml.description "Next-L Enju, an open source integrated library system developed by Project Next-L"
    xml.language @locale
    xml.ttl "60"
    if @manifestations
      xml.items do
        xml.tag! "rdf:Seq" do
          for manifestation in @manifestations
            xml.tag! "rdf:li", 'rdf:resource' => "http://#{LibraryGroup.url}manifestations/#{manifestation.id}"
          end
        end
      end
    end
  }
  for manifestation in @manifestations
    xml.item do
      xml.title h(manifestation.original_title)
      xml.tag! 'dc:date', h(manifestation.created_at.utc.iso8601)
      xml.tag! 'dc:creator', manifestation.creator.join(' ') unless manifestation.creators.empty?
      xml.tag! 'dc:contributor', manifestation.contributor.join(' ') unless manifestation.contributors.empty?
      xml.tag! 'dc:publisher', manifestation.publisher.join(' ') unless manifestation.publishers.empty?
      xml.tag! 'dc:identifier', "urn:ISBN:#{manifestation.isbn}" if manifestation.isbn.present?
      xml.tag! 'dc:description', manifestation.description
      xml.link manifestation_url(manifestation)
      manifestation.subjects.each do |subject|
        xml.tag! "foaf:topic", "rdf:resource" => subject_url(subject)
      end
    end
  end
}
