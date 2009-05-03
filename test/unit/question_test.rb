require File.dirname(__FILE__) + '/../test_helper'

class QuestionTest < ActiveSupport::TestCase
  fixtures :questions

  # Replace this with your real tests.
  def test_should_get_refkyo_search
    result = Question.search_porta('Yahoo', 'refkyo')
    assert result.items.size > 0
    assert_not_nil result.channel.totalResults
  end
end
