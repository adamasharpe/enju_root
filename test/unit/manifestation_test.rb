# -*- encoding: utf-8 -*-
# == Schema Information
#
# Table name: manifestations
#
#  id                              :integer          not null, primary key
#  original_title                  :text             not null
#  title_alternative               :text
#  title_transcription             :text
#  classification_number           :string(255)
#  identifier                      :string(255)
#  date_of_publication             :datetime
#  date_copyrighted                :datetime
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  deleted_at                      :datetime
#  access_address                  :string(255)
#  language_id                     :integer          default(1), not null
#  carrier_type_id                 :integer          default(1), not null
#  extent_id                       :integer          default(1), not null
#  start_page                      :integer
#  end_page                        :integer
#  height                          :integer
#  width                           :integer
#  depth                           :integer
#  isbn                            :string(255)
#  isbn10                          :string(255)
#  wrong_isbn                      :string(255)
#  nbn                             :string(255)
#  lccn                            :string(255)
#  oclc_number                     :string(255)
#  issn                            :string(255)
#  price                           :integer
#  fulltext                        :text
#  volume_number_list              :string(255)
#  issue_number_list               :string(255)
#  serial_number_list              :string(255)
#  edition                         :integer
#  note                            :text
#  produces_count                  :integer          default(0), not null
#  exemplifies_count               :integer          default(0), not null
#  embodies_count                  :integer          default(0), not null
#  resource_has_subjects_count     :integer          default(0), not null
#  repository_content              :boolean          default(FALSE), not null
#  lock_version                    :integer          default(0), not null
#  required_role_id                :integer          default(1), not null
#  state                           :string(255)
#  required_score                  :integer          default(0), not null
#  frequency_id                    :integer          default(1), not null
#  subscription_master             :boolean          default(FALSE), not null
#  series_statement_id             :integer
#  attachment_file_name            :string(255)
#  attachment_content_type         :string(255)
#  attachment_file_size            :integer
#  attachment_updated_at           :datetime
#  nii_type_id                     :integer
#  title_alternative_transcription :text
#  description                     :text
#  abstract                        :text
#  available_at                    :datetime
#  valid_until                     :datetime
#  date_submitted                  :datetime
#  date_accepted                   :datetime
#  date_caputured                  :datetime
#  file_hash                       :string(255)
#  pub_date                        :string(255)
#  periodical_master               :boolean          default(FALSE), not null
#  year_of_publication             :integer
#  attachment_fingerprint          :string(255)
#

require 'test_helper'

class ManifestationTest < ActiveSupport::TestCase
  fixtures :manifestations, :expressions, :works, :embodies, :items, :exemplifies,
    :users, :roles, :languages, :reifies, :realizes, :creates, :produces,
    :frequencies, :form_of_works, :content_types, :carrier_types, :countries, :patron_types,
    :manifestation_relationships

  def test_sru_sort_by
    sru = Sru.new({:query => "title=Ruby"})
    assert_equal( {:sort_by => 'created_at', :order => 'desc'}, sru.sort_by)
    sru = Sru.new({:query => 'title=Ruby AND sortBy="title/sort.ascending"', :sortKeys => 'creator,0', :version => '1.2'})
    assert_equal( {:sort_by => 'sort_title', :order => 'asc'}, sru.sort_by)
    sru = Sru.new({:query => 'title=Ruby AND sortBy="title/sort.ascending"', :sortKeys => 'creator,0', :version => '1.1'})
    assert_equal( {:sort_by => 'creator', :order => 'desc'}, sru.sort_by)
    sru = Sru.new({:query => 'title=Ruby AND sortBy="title/sort.ascending"', :sortKeys => 'creator,1', :version => '1.1'})
    assert_equal( {:sort_by => 'creator', :order => 'asc'}, sru.sort_by)
    sru = Sru.new({:query => 'title=Ruby AND sortBy="title'})
    assert_equal( {:sort_by => 'sort_title', :order => 'asc'}, sru.sort_by)
    #TODO ソート基準が入手しやすさの場合の処理
  end

  def test_sru_search 
    sru = Sru.new({:query => "title=Ruby"})
    sru.search
    assert_equal 18, sru.manifestations.size
    assert_equal 'Ruby', sru.manifestations.first.titles.first
    sru = Sru.new({:query => "title=^ruby"})
    sru.search
    assert_equal 9, sru.manifestations.size
    sru = Sru.new({:query => 'title ALL "awk sed"'})
    sru.search
    assert_equal 2, sru.manifestations.size
    assert_equal [184, 116], sru.manifestations.collect{|m| m.id}
    sru = Sru.new({:query => 'title ANY "ruby awk sed"'})
    sru.search
    assert_equal 22, sru.manifestations.size
    sru = Sru.new({:query => 'isbn=9784756137470'})
    sru.search
    assert_equal 114, sru.manifestations.first.id
    sru = Sru.new({:query => "creator=テスト"})
    sru.search
    assert_equal 1, sru.manifestations.size
  end

  def test_sru_search_date
    sru = Sru.new({:query => "from = 2000-09 AND until = 2000-11-01"})
    sru.search
    assert_equal 1, sru.manifestations.size
    assert_equal 120, sru.manifestations.first.id
    sru = Sru.new({:query => "from = 1993-02-24"})
    sru.search
    assert_equal 5, sru.manifestations.size    
    sru = Sru.new({:query => "until = 2006-08-06"})
    sru.search
    assert_equal 4, sru.manifestations.size
  end

  def test_sru_search_relation
    sru = Sru.new({:query => "from = 1993-02-24 AND until = 2006-08-06 AND title=プログラミング"})
    sru.search
    assert_equal 2, sru.manifestations.size
    sru = Sru.new({:query => "until = 2000 AND title=プログラミング"})
    sru.search
    assert_equal 1, sru.manifestations.size
    sru = Sru.new({:query => "from = 2006 AND title=プログラミング"})
    sru.search
    assert_equal 1, sru.manifestations.size
    sru = Sru.new({:query => "from = 2007 OR title=awk"})
    sru.search
    assert_equal 6, sru.manifestations.size
  end

  def test_openurl_search_title
    openurl = Openurl.new({:title => "プログラミング"})
    results = openurl.search
    assert_equal "btitle_text:プログラミング", openurl.query_text
    assert_equal 8, results.size
    openurl = Openurl.new({:jtitle => "テスト"})
    results = openurl.search
    assert_equal 5, results.size
    assert_equal "jtitle_text:テスト", openurl.query_text
    openurl = Openurl.new({:atitle => "記事"})
    results = openurl.search
    assert_equal 3, results.size
    assert_equal "atitle_text:記事", openurl.query_text
    openurl = Openurl.new({:atitle => "記事", :jtitle => "１月号"})
    results = openurl.search
    assert_equal 2, results.size
  end
  def test_openurl_search_patron
    openurl = Openurl.new({:aulast => "Administrator"})
    results = openurl.search
    assert_equal "au_text:Administrator", openurl.query_text
    assert_equal 6, results.size
    openurl = Openurl.new({:aufirst => "名称"})
    results = openurl.search
    assert_equal "au_text:名称", openurl.query_text
    assert_equal 1, results.size
    openurl = Openurl.new({:au => "テスト"})
    results = openurl.search
    assert_equal "au_text:テスト", openurl.query_text
    assert_equal 1, results.size
    openurl = Openurl.new({:pub => "Administrator"})
    results = openurl.search
    assert_equal "publisher_text:Administrator", openurl.query_text
    assert_equal 4, results.size
  end
  def test_openurl_search_isbn
    openurl = Openurl.new({:api => "openurl", :isbn => "4798"})
    results = openurl.search
    assert_equal "isbn_text:4798*", openurl.query_text
    assert_equal 2, results.size
  end
  def test_openurl_search_issn
    openurl = Openurl.new({:api => "openurl", :issn => "1234"})
    results = openurl.search
    assert_equal "issn_text:1234*", openurl.query_text
    assert_equal 2, results.size
  end
  def test_openurl_search_any
    openurl = Openurl.new({:any => "テスト"})
    results = openurl.search
    assert_equal 8, results.size
  end
  def test_openurl_search_multi
    openurl = Openurl.new({:btitle => "CGI Perl プログラミング"})
    results = openurl.search
    assert_equal 3, results.size
    openurl = Openurl.new({:jtitle => "テスト", :pub => "テスト"})
    results = openurl.search
    assert_equal 2, results.size
  end
  def test_openurl_search_error
    assert_raise(OpenurlQuerySyntaxError){ Openurl.new({:isbn => "12345678901234"})}
    assert_raise(OpenurlQuerySyntaxError){Openurl.new(:issn => "1234abcd")}
    assert_raise(OpenurlQuerySyntaxError){Openurl.new(:aufirst => "テスト 名称")}
  end
  def test_manifestation_should_embody_expression
    assert manifestations(:manifestation_00001).embodies?(expressions(:expression_00001))
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

  def test_manifestation_should_respond_to_pickup
    assert Manifestation.pickup
  end

  def test_manifestation_should_respond_to_title
    assert manifestations(:manifestation_00001).title
  end

  def test_manifestation_should_not_have_parent_of_series
    assert_nil manifestations(:manifestation_00001).parent_of_series
  end

  def test_manifestation_should_response_to_extract_text
    assert_nil manifestations(:manifestation_00001).extract_text
  end

  def test_manifestation_should_response_to_derived_manifestations_by_solr
    assert manifestations(:manifestation_00001).derived_manifestations_by_solr
  end
end
