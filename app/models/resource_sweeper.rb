class ResourceSweeper < ActionController::Caching::Sweeper
  observe Manifestation, Item, Expression, Work, Reify, Embody, Exemplify, Create, Realize, Produce, Own, BookmarkedResource, Bookmark, Tag, Patron, Library
  def after_save(record)
    case
    when record.is_a?(Patron)
      record.manifestations.each do |manifestation|
        expire_manifestation_fragment(manifestation)
      end
    when record.is_a?(Work)
      expire_editable_fragment(record)
      record.expressions.each do |expression|
        expire_editable_fragment(expression)
        expression.manifestations.each do |manifestation|
          expire_manifestation_fragment(manifestation)
        end
      end
    when record.is_a?(Expression)
      expire_editable_fragment(record)
      record.manifestations.each do |manifestation|
        expire_manifestation_fragment(manifestation)
      end
    when record.is_a?(Manifestation)
      expire_manifestation_fragment(record)
      record.expressions.each do |expression|
        expire_editable_fragment(expression)
      end
    when record.is_a?(Item)
      expire_editable_fragment(record)
      expire_manifestation_fragment(record.manifestation)
    when record.is_a?(Library)
      expire_fragment(:controller => :libraries, :action => :index, :action_suffix => 'menu')
    when record.is_a?(Bookmark)
      # Not supported by Memcache
      # expire_fragment(%r{manifestations/\d*})
      expire_manifestation_fragment(record.bookmarked_resource.manifestation)
      expire_fragment(:controller => :tags, :action => :index, :action_suffix => 'user_tag_cloud', :user_id => record.user.login)
      expire_fragment(:controller => :tags, :action => :index, :action_suffix => 'public_tag_cloud')
    when record.is_a?(BookmarkedResource)
      expire_manifestation_fragment(record.manifestation)
    when record.is_a?(Tag)
      record.tagged.each do |bookmark|
        expire_manifestation_fragment(bookmark.bookmarked_resource.manifestation)
      end
    when record.is_a?(Subject)
      record.manifestations.each do |manifestation|
        expire_manifestation_fragment(manifestation)
      end
    when record.is_a?(Concept)
      expire_fragment(:controller => :concepts, :action => :show, :id => record.id)
    when record.is_a?(Place)
      expire_fragment(:controller => :places, :action => :show, :id => record.id)
    when record.is_a?(Create)
      expire_editable_fragment(record.patron)
      expire_editable_fragment(record.work)
      record.work.expressions.each do |expression|
        expire_editable_fragment(expression)
        expression.manifestations.each do |manifestation|
          expire_manifestation_fragment(manifestation)
        end
      end
    when record.is_a?(Realize)
      expire_editable_fragment(record.patron)
      expire_editable_fragment(record.expression)
      record.expression.manifestations.each do |manifestation|
        expire_manifestation_fragment(manifestation)
      end
    when record.is_a?(Produce)
      expire_editable_fragment(record.patron)
      expire_manifestation_fragment(record.manifestation)
      record.manifestation.expressions.each do |expression|
        expire_editable_fragment(expression)
        expression.manifestations.each do |manifestation|
          expire_manifestation_fragment(manifestation)
        end
      end
    when record.is_a?(Own)
      expire_editable_fragment(record.patron)
      expire_editable_fragment(record.item)
      expire_manifestation_fragment(record.item.manifestation)
    when record.is_a?(Reify)
      expire_editable_fragment(record.work)
      expire_editable_fragment(record.expression)
      record.expression.manifestations.each do |manifestation|
        expire_manifestation_fragment(manifestation)
      end
    when record.is_a?(Embody)
      expire_editable_fragment(record.expression)
      expire_manifestation_fragment(record.manifestation)
      record.manifestation.expressions.each do |expression|
        expire_editable_fragment(expression)
      end
      record.expression.manifestations.each do |manifestation|
        expire_manifestation_fragment(manifestation)
      end
    when record.is_a?(Exemplify)
      expire_manifestation_fragment(record.manifestation)
      expire_editable_fragment(record.item)
    end
  end

  def after_destroy(record)
    after_save(record)
  end

  def expire_editable_fragment(record)
    case
    when record.is_a?(Patron)
      expire_fragment(:controller => :patrons, :action => :show, :id => record.id, :editable => true)
      expire_fragment(:controller => :patrons, :action => :show, :id => record.id, :editable => false)
    when record.is_a?(Work)
      expire_fragment(:controller => :works, :action => :show, :id => record.id, :editable => true)
      expire_fragment(:controller => :works, :action => :show, :id => record.id, :editable => false)
    when record.is_a?(Expression)
      expire_fragment(:controller => :expressions, :action => :show, :id => record.id, :editable => true)
      expire_fragment(:controller => :expressions, :action => :show, :id => record.id, :editable => false)
    when record.is_a?(Item)
      expire_fragment(:controller => :items, :action => :show, :id => record.id, :editable => true)
      expire_fragment(:controller => :items, :action => :show, :id => record.id, :editable => false)
    end
  end

  def expire_manifestation_fragment(manifestation)
    fragments = %w[detail_1 detail_2 pickup index_list book_jacket show_index show_limited_authors show_all_authors show_editors_and_publishers show_holding tags]
    expire_fragment(:controller => :manifestations, :action => :index, :action_suffix => 'numdocs')
    fragments.each do |fragment|
      if manifestation
        expire_fragment(:controller => :manifestations, :action => :show, :id => manifestation.id, :action_suffix => fragment, :editable => true)
        expire_fragment(:controller => :manifestations, :action => :show, :id => manifestation.id, :action_suffix => fragment, :editable => false)
      end
    end
  end
end
