xml.instruct! :xml, :version=>"1.0" 
xml.rss('version' => "2.0",
        'xmlns:opensearch' => "http://a9.com/-/spec/opensearch/1.1/",
        'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
        'xmlns:atom' => "http://www.w3.org/2005/Atom"){
  xml.channel{
    xml.title t('news_post.library_group_news_post', :library_group_name => @library_group.display_name.localize)
    xml.link news_posts_url
    xml.description "Project Next-L Enju, an open source integrated library system developed by Project Next-L"
    xml.language @locale
    xml.ttl "60"
    xml.tag! "atom:link", :rel => 'self', :href => news_posts_url(:format => :rss)
    xml.tag! "atom:link", :rel => 'alternate', :href => root_url
    xml.tag! "atom:link", :rel => 'search', :type => 'application/opensearchdescription+xml', :href => opensearch_url
    unless params[:query].blank?
      xml.tag! "opensearch:startIndex", @news_posts.offset + 1
      xml.tag! "opensearch:itemsPerPage", @news_posts.per_page
    end
    if @news_posts
      for news_post in @news_posts
        xml.item do
          xml.title h(news_post.title)
          xml.description(news_post.body)
          # rfc822
          xml.pubDate h(news_post.created_at.rfc2822)
          xml.link news_post_url(news_post)
          xml.guid news_post_url(news_post), :isPermaLink => "true"
        end
      end
    end
  }
}