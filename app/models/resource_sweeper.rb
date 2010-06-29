class ResourceSweeper < ActionController::Caching::Sweeper
  observe Manifestation, Item, Expression, Work, Reify, Embody, Exemplify,
    Create, Realize, Produce, Own, Bookmark, Patron, Language,
    Library, Basket, Checkin, WorkHasWork, ExpressionHasExpression,
    ManifestationHasManifestation, ItemHasItem, PatronHasPatron,
    SeriesStatement, SubjectHeadingType, PictureFile, Shelf, Tag, Answer

  def after_save(record)
    case
    when record.is_a?(Patron)
      expire_editable_fragment(record)
      record.works.each do |work|
        expire_editable_fragment(work)
      end
      record.expressions.each do |expression|
        expire_editable_fragment(expression)
      end
      record.manifestations.each do |manifestation|
        expire_editable_fragment(manifestation)
      end
      record.donated_items.each do |item|
        expire_editable_fragment(item)
      end
      record.patrons.each do |patron|
        expire_editable_fragment(patron)
      end
    when record.is_a?(Work)
      expire_editable_fragment(record)
      record.expressions.each do |expression|
        expire_editable_fragment(expression)
        expression.manifestations.each do |manifestation|
          expire_editable_fragment(manifestation)
        end
      end
      record.patrons.each do |patron|
        expire_editable_fragment(patron)
      end
    when record.is_a?(Expression)
      expire_editable_fragment(record)
      record.manifestations.each do |manifestation|
        expire_editable_fragment(manifestation)
      end
      record.patrons.each do |patron|
        expire_editable_fragment(patron)
      end
    when record.is_a?(Manifestation)
      expire_editable_fragment(record)
      record.expressions.each do |expression|
        expire_editable_fragment(expression)
      end
      record.items.each do |item|
        expire_editable_fragment(item)
      end
      record.patrons.each do |patron|
        expire_editable_fragment(patron)
      end
    when record.is_a?(Item)
      expire_editable_fragment(record)
      expire_editable_fragment(record.manifestation, ['detail'])
      record.patrons.each do |patron|
        expire_editable_fragment(patron)
      end
      record.donors.each do |donor|
        expire_editable_fragment(donor)
      end
    when record.is_a?(Library)
      expire_fragment(:controller => :libraries, :action => :index, :action_suffix => 'menu')
    when record.is_a?(Shelf)
      # TODO: 書架情報が更新されたときのキャッシュはバッチで削除する
      #record.items.each do |item|
      #  expire_editable_fragment(item, ['holding'])
      #end
    when record.is_a?(Bookmark)
      # Not supported by Memcache
      # expire_fragment(%r{manifestations/\d*})
      expire_editable_fragment(record.manifestation)
      expire_tag_cloud(record)
    when record.is_a?(Tag)
      record.taggings.collect(&:taggable).each do |taggable|
        expire_editable_fragment(taggable)
      end
    when record.is_a?(Subject)
      expire_editable_fragment(record)
      record.works.each do |work|
        expire_editable_fragment(work)
        work.manifestations.each do |manifestation|
          expire_editable_fragment(manifestation)
        end
      end
      record.classifications.each do |classification|
        expire_editable_fragment(classification)
      end
    when record.is_a?(Classification)
      expire_editable_fragment(record)
      record.subjects.each do |subject|
        expire_editable_fragment(subject)
      end
    when record.is_a?(Create)
      expire_editable_fragment(record.patron)
      expire_editable_fragment(record.work)
      record.work.expressions.each do |expression|
        expire_editable_fragment(expression)
        expression.manifestations.each do |manifestation|
          expire_editable_fragment(manifestation)
        end
      end
    when record.is_a?(Realize)
      expire_editable_fragment(record.patron)
      expire_editable_fragment(record.expression)
      record.expression.manifestations.each do |manifestation|
        expire_editable_fragment(manifestation)
        manifestation.expressions.each do |expression|
          expire_editable_fragment(expression)
        end
      end
    when record.is_a?(Produce)
      expire_editable_fragment(record.patron)
      expire_editable_fragment(record.manifestation)
      record.manifestation.expressions.each do |expression|
        expire_editable_fragment(expression)
        expression.manifestations.each do |manifestation|
          expire_editable_fragment(manifestation)
        end
      end
    when record.is_a?(Own)
      expire_editable_fragment(record.patron)
      expire_editable_fragment(record.item)
      expire_editable_fragment(record.item.manifestation)
    when record.is_a?(Reify)
      expire_editable_fragment(record.work)
      expire_editable_fragment(record.expression)
      record.expression.manifestations.each do |manifestation|
        expire_editable_fragment(manifestation)
      end
    when record.is_a?(Embody)
      expire_editable_fragment(record.expression)
      expire_editable_fragment(record.manifestation)
      record.manifestation.expressions.each do |expression|
        expire_editable_fragment(expression)
      end
      record.expression.manifestations.each do |manifestation|
        expire_editable_fragment(manifestation)
      end
    when record.is_a?(Exemplify)
      expire_editable_fragment(record.manifestation)
      expire_editable_fragment(record.item)
    when record.is_a?(WorkHasWork)
      expire_editable_fragment(record.from_work)
      record.from_work.expressions.each do |expression|
        expire_editable_fragment(expression)
        expression.manifestations.each do |manifestation|
          expire_editable_fragment(manifestation)
        end
      end
      expire_editable_fragment(record.to_work)
      record.to_work.expressions.each do |expression|
        expire_editable_fragment(expression)
        expression.manifestations.each do |manifestation|
          expire_editable_fragment(manifestation)
        end
      end
    when record.is_a?(ExpressionHasExpression)
      expire_editable_fragment(record.from_expression)
      expire_editable_fragment(record.from_expression.work)
      record.from_expression.manifestations.each do |manifestation|
        expire_editable_fragment(manifestation)
      end
      expire_editable_fragment(record.to_expression)
      expire_editable_fragment(record.to_expression.work)
      record.to_expression.manifestations.each do |manifestation|
        expire_editable_fragment(manifestation)
      end
    when record.is_a?(ManifestationHasManifestation)
      expire_editable_fragment(record.from_manifestation)
      record.from_manifestation.expressions.each do |expression|
        expire_editable_fragment(expression)
        expire_editable_fragment(expression.work)
      end
      expire_editable_fragment(record.to_manifestation)
      record.to_manifestation.expressions.each do |expression|
        expire_editable_fragment(expression)
        expire_editable_fragment(expression.work)
      end
    when record.is_a?(ItemHasItem)
      expire_editable_fragment(record.from_item)
      expire_editable_fragment(record.from_item.manifestation) if record.from_item.manifestation
      expire_editable_fragment(record.to_item)
      expire_editable_fragment(record.to_item.manifestation) if record.to_item.manifestation
    when record.is_a?(PatronHasPatron)
      expire_editable_fragment(record.from_patron)
      expire_editable_fragment(record.to_patron)
    when record.is_a?(Basket)
      record.items.each do |item|
        expire_editable_fragment(item, 'holding')
      end
    when record.is_a?(Checkin)
      expire_editable_fragment(record.item, 'holding')
    when record.is_a?(Language)
      Language.all.each do |language|
        expire_fragment(:controller => 'page', :locale => language.iso_639_1)
      end
    when record.is_a?(SeriesStatement)
      record.manifestations.each do |manifestation|
        expire_editable_fragment(manifestation, ['detail'])
      end
    when record.is_a?(SubjectHeadingTypeHasSubject)
      expire_editable_fragment(record.subject)
    when record.is_a?(PictureFile)
      case
      when record.picture_attachable.is_a?(Manifestation)
        expire_editable_fragment(record.picture_attachable, ['picture_file', 'book_jacket'])
      when record.picture_attachable.is_a?(Patron)
        expire_editable_fragment(record.picture_attachable, ['picture_file'])
      end
    when record.is_a?(Answer)
      record.items.each do |item|
        expire_editable_fragment(item.manifestation, ['detail'])
      end
    end
  end

  def after_destroy(record)
    after_save(record)
  end

  def expire_editable_fragment(record, fragments = nil)
    if record
      if record.is_a?(Manifestation)
        expire_manifestation_cache(record, fragments)
      else
        I18n.available_locales.each do |locale|
          Role.all.each do |role|
            expire_fragment(:controller => record.class.to_s.pluralize.downcase, :action => :show, :id => record.id, :role => role.name, :locale => locale.to_s)
            if fragments
              fragments.each do |fragment|
                expire_fragment(:controller => record.class.to_s.pluralize.downcase, :action => :show, :id => record.id, :action_suffix => fragment, :role => role.name, :locale => locale.to_s)
              end
            end
          end
        end
      end
    end
  end

  def expire_manifestation_cache(manifestation, fragments)
    fragments = %w[detail pickup index_list book_jacket show_index show_limited_authors show_all_authors show_contributors_and_publishers title show_xisbn picture_file title_reserve index_list] if fragments.nil?
    expire_fragment(:controller => :manifestations, :action => :index, :action_suffix => 'numdocs')
    fragments.each do |fragment|
      expire_manifestation_fragment(manifestation, fragment)
    end
    manifestation.bookmarks.each do |bookmark|
      expire_tag_cloud(bookmark)
    end
    Rails.cache.delete("xisbn_#{manifestation.id}")
  end

  def expire_manifestation_fragment(manifestation, fragment)
    if manifestation
      I18n.available_locales.each do |locale|
        Role.all.each do |role|
          ['atom', 'csv', 'mods', 'oai_list_identifiers', 'oai_list_records', 'rdf', 'rss'].each do |format|
            expire_fragment(:controller => :manifestations, :action => :show, :id => manifestation.id, :locale => locale.to_s, :role => role.name, :format_suffix => format, :user_id => nil)
          end
          expire_fragment(:controller => :manifestations, :action => :show, :id => manifestation.id, :action_suffix => fragment, :locale => locale.to_s, :role => role.name, :user_id => nil)
        end
      end
    end
  end

  def expire_tag_cloud(bookmark)
    I18n.available_locales.each do |locale|
      Role.all.each do |role|
        expire_fragment(:controller => :tags, :action => :index, :action_suffix => 'user_tag_cloud', :user_id => bookmark.user.username, :locale => locale, :role => role.name, :user_id => nil)
        expire_fragment(:controller => :tags, :action => :index, :action_suffix => 'public_tag_cloud', :locale => locale, :role => role.name, :user_id => nil)
      end
    end
  end
end
