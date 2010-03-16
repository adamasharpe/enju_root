#!/usr/bin/env ruby
#require 'rubygems'
#require 'fileutils'
require 'cgi'
#require 'builder/xmlmarkup'
require 'sru'

if @sru
  unless @sru.extra_response_data.empty?
    @extra_response = true
    @facets = @sru.extra_response_data[:facets]
    @dpid = @sru.extra_response_data[:dpid]
    @webget = @sru.extra_response_data[:webget]
    @digitalize = @sru.extra_response_data[:digitalize]
    @porta_type = @sru.extra_response_data[:porta_type]
    @payment = @sru.extra_response_data[:payment]
    @ndc = @sru.extra_response_data[:ndc]
    @date = @sru.extra_response_data[:date]
  end

  @version = @sru.version
  @packing = @sru.packing
  @number_of_records = @manifestations.total_entries
  @next_record_position = @sru.start + @manifestations.size
end
  
def search_retrieve_response!(xml)
  xml.searchRetrieveResponse :xmlns => "http://www.loc.gov/zing/srw/" do
    xml.version @version
    xml.numberOfRecords @number_of_records
    extra_response_data!(xml) if @extra_response
    xml.records do
      @manifestations.each_with_index do |rec, idx|
        xml.record do
          record!(xml, rec, idx + 1)
        end
      end
    end
    xml.nextRecordPosition @next_record_position
  end
end

def extra_response_data!(xml)
  xml.extraResponseData do
    xml.facets @facets do
      lst_tag!(xml, "REPOSITORY_NO", 'dcndl_porta:dpid', @dpid)
      lst_tag!(xml, "WEBGET_TYPE", 'dcndl_porta:type.Web-get', @webget)
      lst_tag!(xml, "DIGITALIZE_TYPE", 'dcndl_porta:type.Digitalize', @digitalize)
      lst_tag!(xml, "PORTA_TYPE", 'dcndl_porta:PORTAType', @porta_type)
      lst_tag!(xml, "PAYMENT_TYPE", 'dcndl_porta:type.Payment', @payment)
      lst_tag!(xml, "NDC", 'int', @ndc)
      lst_tag!(xml, "ISSUED_DATE", 'int', @date)
    end
  end
end

def lst_tag!(xml, lst_name, tag_name, hash)
  xml.lst :name => lst_name do
    value_sort(hash).each do |item|
      xml.tag! tag_name, {:name => item[0]}, item[1]
    end
  end
end

def record!(xml, rec, position)
  xml.recordSchema 'info:srw/schema/1/dc-v1.1'
  xml.recordPacking @packing
  xml.recordData{|x| x << (/\Axml\Z/io =~ @packing ? get_recoad(rec) : CGI::escapeHTML(get_recoad(rec)))}
  xml.recordPosition position
end

def get_recoad(mf)
  data = <<EOB
<srw_dc:dc
xmlns:dc="http://purl.org/dc/elements/1.1/"
xmlns:srw_dc="info:srw/schema/1/dc-v1.1"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="info:srw/schema/1/dc-v1.1
http://www.loc.gov/standards/sru/dc-schema.xsd">
<dc:title>#{mf.title}</dc:title>
<dc:creator>#{mf.author}</dc:creator>
<dc:description></dc:description>
<dc:publisher>#{mf.publisher}</dc:publisher>
</srw_dc:dc>
EOB
  data
end

def value_sort(hash)
  hash.to_a.sort do |a, b|
    (b[1] <=> a[1]) * 2 + (a[0] <=> b[0])
  end
end

xml = Builder::XmlMarkup.new :indent => 2
xml.instruct! directive_tag=:xml, :encoding=> 'UTF-8'
search_retrieve_response!(xml)