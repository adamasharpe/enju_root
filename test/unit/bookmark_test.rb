require 'test_helper'

class BookmarkTest < ActiveSupport::TestCase
  fixtures :bookmarks,
    :users, :patrons, :patron_types, :languages, :countries,
    :items, :manifestations, :exemplifies,
    :expressions, :works, :carrier_types, :content_types,
    :shelves, :circulation_statuses, :libraries, :library_groups,
    :users, :user_groups

  def test_bookmark_sheved
    assert bookmarks(:bookmark_00001).shelved?
  end

  #def test_bookmark_create_bookmark_item
  #  old_count = Item.count
  #  bookmark = users(:user1).bookmarks.create(:manifestation_id => 5, :title => 'test')
  #  assert_not_nil bookmarks(:bookmark_00001).manifestation.items
  #  assert_equal old_count + 1, Item.count
  #end

  def test_bookmark_create_bookmark_with_url
    old_count = Bookmark.count
    old_work_count = Work.count
    old_expression_count = Expression.count
    old_manifestation_count = Manifestation.count
    old_item_count = Item.count
    bookmark = users(:user1).bookmarks.create(:url => 'http://www.example.com/', :title => 'test')
    assert_equal old_count + 1, Bookmark.count
    assert_equal old_manifestation_count + 1, Manifestation.count
    assert_equal old_work_count + 1, Work.count
    assert_equal old_expression_count + 1, Expression.count
    assert_equal old_item_count + 1, Item.count
  end

  def test_bookmark_create_bookmark_with_local_url
    old_count = Bookmark.count
    old_work_count = Work.count
    old_expression_count = Expression.count
    old_manifestation_count = Manifestation.count
    old_item_count = Item.count
    bookmark = users(:user1).bookmarks.create(:url => "#{LibraryGroup.site_config.url}manifestations/1", :title => 'test')
    assert_equal old_count + 1, Bookmark.count
    assert_equal old_manifestation_count, Manifestation.count
    bookmark.create_frbr_object
    assert_equal old_work_count, Work.count
    assert_equal old_expression_count, Expression.count
    assert_equal old_item_count, Item.count
  end

end
