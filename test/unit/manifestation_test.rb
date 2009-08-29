require File.dirname(__FILE__) + '/../test_helper'

class ManifestationTest < ActiveSupport::TestCase
  fixtures :manifestations, :expressions, :works, :embodies, :items, :exemplifies,
    :reserves, :users, :roles, :languages, :reifies, :realizes, :creates, :produces,
    :frequencies, :form_of_works, :expression_forms, :carrier_types, :countries, :patron_types

  # Replace this with your real tests.
  def test_manifestation_should_embody_expression
    assert manifestations(:manifestation_00001).embodies?(expressions(:expression_00001))
  end

  def test_reserved
    assert manifestations(:manifestation_00007).is_reserved_by(users(:admin))
  end

  def test_not_reserved
    assert_equal false, manifestations(:manifestation_00007).is_reserved_by(users(:user1))
  end

  def test_manifestation_should_show_languages
    assert manifestations(:manifestation_00001).languages
  end

  #def test_manifestation_should_show_oai_dc
  #  assert manifestations(:manifestation_00001).to_oai_dc
  #end

  def test_manifestation_should_get_number_of_pages
    assert_equal 100, manifestations(:manifestation_00001).number_of_pages
  end

  def test_manifestation_should_import_isbn
    assert Manifestation.import_isbn('4797327030')
  end

  def test_youtube_id
    assert_equal manifestations(:manifestation_00022).youtube_id, 'BSHBzd9ftDE'
  end

  def test_nicovideo_id
    assert_equal manifestations(:manifestation_00023).nicovideo_id, 'sm3015373'
  end

  def test_pickup
    assert Manifestation.pickup
  end

  def title
    assert manifestations(:manifestation_00001).title
  end
end
