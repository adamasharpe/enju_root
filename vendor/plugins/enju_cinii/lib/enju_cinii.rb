require 'rss'
module EnjuCinii
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def enju_cinii
      include EnjuCinii::InstanceMethods
      #Atom::Feed.add_extension_namespace :opensearch, "http://a9.com/-/spec/opensearch/1.1/"
      #Atom::Feed.element "opensearch:totalResults"
      RSS::Atom::Feed.install_text_element("opensearch:totalResults", "http://a9.com/-/spec/opensearch/1.1/", "?", "totalResults", :text, "opensearch:totalResults")
      RSS::BaseListener.install_get_text_element "http://a9.com/-/spec/opensearch/1.1/", "totalResults", "totalResults="
    end

    def search_cinii(query)
      url = "http://ci.nii.ac.jp/opensearch/search?q=#{URI.encode(query)}&format=atom"
      #Atom::Feed.load_feed(URI.parse(url))
      feed = RSS::Parser.parse(url, false)
    end
  end

  module InstanceMethods
    def cinii_feed(page = 1, count = 10)
      start = (page - 1) * count + 1
      if self.respond_to?(:issn)
        url = "http://ci.nii.ac.jp/opensearch/search?issn=#{self.issn}&count=#{count}&start=#{start}&format=atom"
      end
      #Atom::Feed.load_feed(URI.parse(url))
      feed = RSS::Parser.parse(url, false)
    end
  end
end
