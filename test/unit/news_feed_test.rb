require File.dirname(__FILE__) + '/../test_helper'

class NewsFeedTest < ActiveSupport::TestCase
  fixtures :news_feeds, :library_groups

  # Replace this with your real tests.
  def test_should_get_content
    assert news_feeds(:news_feed_00001).content
  end

  def test_should_not_get_invalid_content
    assert_nil news_feeds(:news_feed_00003).content
  end

  def test_should_reload
    assert news_feeds(:news_feed_00001).force_reload
  end

  def test_should_get_atom_content
    assert news_feeds(:news_feed_00004).content
  end

  #def test_should_get_auto_discovery
  #  assert news_feeds(:news_feed_00005).content
  #end

  #def test_should_get_local_feed
  #  assert news_feeds(:news_feed_00006).content
  #end
end
