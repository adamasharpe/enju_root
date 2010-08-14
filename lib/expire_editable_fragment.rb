module ExpireEditableFragment
  def expire_editable_fragment(record, fragments = nil)
    if record
      if record.is_a?(Resource)
        expire_manifestation_cache(record, fragments)
      else
        I18n.available_locales.each do |locale|
          Rails.cache.fetch('role_all'){Role.all}.each do |role|
            expire_fragment(:controller => record.class.to_s.pluralize.downcase, :action => :show, :id => record.id, :role => role.name, :locale => locale.to_s)
            if fragments
              fragments.each do |fragment|
                expire_fragment(:controller => record.class.to_s.pluralize.downcase, :action => :show, :id => record.id, :page => fragment, :role => role.name, :locale => locale.to_s)
              end
            end
          end
        end
      end
    end
  end

  def expire_manifestation_cache(manifestation, fragments)
    fragments = %w[detail pickup book_jacket title show_xisbn picture_file title_reserve show_list edit_list reserve_list] if fragments.nil?
    expire_fragment(:controller => :resources, :action => :index, :page => 'numdocs')
    fragments.each do |fragment|
      expire_manifestation_fragment(manifestation, fragment)
    end
    manifestation.bookmarks.each do |bookmark|
      expire_tag_cloud(bookmark)
    end
  end

  def expire_manifestation_fragment(manifestation, fragment, formats = [nil, 'html'])
    formats = ['atom', 'csv', 'html', 'mods', 'oai_list_identifiers', 'oai_list_records', 'rdf', 'rss'] if formats.empty?
    if manifestation
      I18n.available_locales.each do |locale|
        Rails.cache.fetch('role_all'){Role.all}.each do |role|
          formats.each do |format|
            expire_fragment(:controller => :resources, :action => :show, :id => manifestation.id, :locale => locale.to_s, :role => role.name, :page => fragment, :user_id => nil, :format => format)
          end
        end
      end
    end
  end

  def expire_tag_cloud(bookmark)
    I18n.available_locales.each do |locale|
      Rails.cache.fetch('role_all'){Role.all}.each do |role|
        expire_fragment(:controller => :tags, :action => :index, :page => 'user_tag_cloud', :user_id => bookmark.user.username, :locale => locale, :role => role.name, :user_id => nil)
        expire_fragment(:controller => :tags, :action => :index, :page => 'public_tag_cloud', :locale => locale, :role => role.name, :user_id => nil)
      end
    end
  end

end
