require 'test_helper'

class ManifestationsControllerTest < ActionController::TestCase
  fixtures :manifestations, :carrier_types, :work_has_subjects, :languages, :subjects, :subject_types,
    :works, :form_of_works, :realizes,
    :expressions, :content_types, :frequencies,
    :items, :library_groups, :libraries, :shelves, :languages, :exemplifies,
    :embodies, :patrons, :user_groups, :users,
    :roles,
    :search_histories


  def test_api_sru_template
    get :index, :format => 'sru', :query => 'title=ruby', :operation => 'searchRetrieve'
    assert_response :success
    assert_template('manifestations/index')
  end

  def test_api_sru_error
    get :index, :format => 'sru'
    assert_response :success
    assert_template('manifestations/explain')
  end

  def test_guest_should_get_index
    if configatron.write_search_log_to_file
      assert_no_difference('SearchHistory.count') do
        get :index
      end
    else
      assert_difference('SearchHistory.count') do
        get :index
      end
    end
    get :index
    assert_response :success
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_xml
    if configatron.write_search_log_to_file
      assert_no_difference('SearchHistory.count') do
        get :index, :format => 'xml'
      end
    else
      assert_difference('SearchHistory.count') do
        get :index, :format => 'xml'
      end
    end
    assert_response :success
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_csv
    if configatron.write_search_log_to_file
      assert_no_difference('SearchHistory.count') do
        get :index, :format => 'csv'
      end
    else
      assert_difference('SearchHistory.count') do
        get :index, :format => 'csv'
      end
    end
    assert_response :success
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_mods
    get :index, :format => 'mods'
    assert_response :success
    assert_template('manifestations/index')
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_rdf
    get :index, :format => 'rdf'
    assert_response :success
    assert_template('manifestations/index')
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_oai_without_resumption_token
    get :index, :format => 'oai'
    assert_response :success
    assert_template('manifestations/index')
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_oai_list_identifiers
    get :index, :format => 'oai', :verb => 'ListIdentifiers'
    assert_response :success
    assert_template('manifestations/list_identifiers')
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_oai_list_records
    get :index, :format => 'oai', :verb => 'ListRecords'
    assert_response :success
    assert_template('manifestations/list_records')
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_oai_get_record_without_identifier
    get :index, :format => 'oai', :verb => 'GetRecord'
    assert_response :success
    assert_template('manifestations/index')
    assert_nil assigns(:manifestation)
  end

  def test_guest_should_get_index_oai_get_record
    get :index, :format => 'oai', :verb => 'GetRecord', :identifier => 'oai:localhost:manifestations-1'
    assert_template('manifestations/show')
    assert assigns(:manifestation)
  end

  def test_user_should_not_create_search_history_if_log_is_written_to_file
    sign_in users(:user1)
    if configatron.write_search_log_to_file
      assert_no_difference('SearchHistory.count') do
        get :index, :query => 'test'
      end
    else
      assert_difference('SearchHistory.count') do
        get :index, :query => 'test'
      end
    end
    assert_response :success
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_with_manifestation_id
    get :index, :manifestation_id => 1
    assert_response :success
    assert assigns(:manifestation)
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_with_patron_id
    get :index, :patron_id => 1
    assert_response :success
    assert assigns(:patron)
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_with_expression
    get :index, :expression_id => 1
    assert_response :success
    assert assigns(:expression)
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_with_query
    get :index, :query => '2005'
    assert_response :success
    assert assigns(:manifestations)
  end

  def test_guest_should_get_index_with_page_number
    get :index, :query => '2005', :number_of_pages_at_least => 1, :number_of_pages_at_most => 100
    assert_response :success
    assert assigns(:manifestations)
    assert_equal '2005 number_of_pages_i:[1 TO 100]', assigns(:query)
  end

  def test_guest_should_get_index_with_pub_date_from
    get :index, :query => '2005', :pub_date_from => '2000'
    assert_response :success
    assert assigns(:manifestations)
    assert_equal '2005 date_of_publication_d:[1999-12-31T15:00:00Z TO *]', assigns(:query)
  end

  def test_guest_should_get_index_with_pub_date_to
    get :index, :query => '2005', :pub_date_to => '2000'
    assert_response :success
    assert assigns(:manifestations)
    assert_equal '2005 date_of_publication_d:[* TO 1999-12-31T15:00:00Z]', assigns(:query)
  end

  def test_guest_should_get_index_all_facet
    get :index, :query => '2005', :view => 'all_facet'
    assert_response :success
    assert assigns(:carrier_type_facet)
    assert assigns(:language_facet)
    assert assigns(:library_facet)
    #assert assigns(:subject_facet)
  end

  def test_guest_should_get_index_carrier_type_facet
    get :index, :query => '2005', :view => 'carrier_type_facet'
    assert_response :success
    assert assigns(:carrier_type_facet)
  end

  def test_guest_should_get_index_language_facet
    get :index, :query => '2005', :view => 'language_facet'
    assert_response :success
    assert assigns(:language_facet)
  end

  def test_guest_should_get_index_library_facet
    get :index, :query => '2005', :view => 'library_facet'
    assert_response :success
    assert assigns(:library_facet)
  end

  #def test_guest_should_get_index_subject_facet
  #  get :index, :query => '2005', :view => 'subject_facet'
  #  assert_response :success
  #  assert assigns(:subject_facet)
  #end

  def test_guest_should_get_index_tag_cloud
    get :index, :query => '2005', :view => 'tag_cloud'
    assert_response :success
    assert assigns(:tags)
  end

  #def test_user_should_save_search_history_when_allowed
  #  old_search_history_count = SearchHistory.count
  #  sign_in users(:admin)
  #  get :index, :query => '2005'
  #  assert_response :success
  #  assert assigns(:manifestations)
  #  assert_equal old_search_history_count + 1, SearchHistory.count
  #end

  def test_user_should_get_index
    sign_in users(:user1)
    get :index
    assert_response :success
    assert assigns(:manifestations)
  end

  #def test_user_should_not_save_search_history_when_not_allowed
  #  old_search_history_count = SearchHistory.count
  #  sign_in users(:user1)
  #  get :index
  #  assert_response :success
  #  assert assigns(:manifestations)
  #  assert_equal old_search_history_count, SearchHistory.count
  #end

  def test_librarian_should_get_index
    sign_in users(:librarian1)
    get :index
    assert_response :success
    assert assigns(:manifestations)
  end

  def test_admin_should_get_index
    sign_in users(:admin)
    get :index
    assert_response :success
    assert assigns(:manifestations)
  end

  def test_guest_should_not_get_new
    get :new
    assert_redirected_to new_user_session_url
  end
  
  #def test_user_should_not_get_new
  #  sign_in users(:user1)
  #  get :new
  #  assert_response :forbidden
  #end
  
  def test_user_should_not_get_new
    sign_in users(:user1)
    get :new
    assert_response :forbidden
  end
  
  #def test_librarian_should_not_get_new_without_expression_id
  #  sign_in users(:librarian1)
  #  get :new
  #  assert_response :redirect
  #  assert_redirected_to expressions_url
  #end
  
  def test_librarian_should_get_new_without_expression_id
    sign_in users(:librarian1)
    get :new
    assert_response :success
  end
  
  def test_librarian_should_get_new_with_expression_id
    sign_in users(:librarian1)
    get :new, :expression_id => 1
    assert_response :success
  end
  
  def test_admin_should_get_new_without_expression_id
    sign_in users(:admin)
    get :new
    assert_response :success
  end
  
  def test_admin_should_get_new_with_expression_id
    sign_in users(:admin)
    get :new, :expression_id => 1
    assert_response :success
  end
  
  def test_guest_should_not_create_manifestation
    old_count = Manifestation.count
    post :create, :manifestation => { :original_title => 'test', :carrier_type_id => 1 }
    assert_equal old_count, Manifestation.count
    
    assert_redirected_to new_user_session_url
  end

  #def test_user_should_not_create_manifestation
  #  sign_in users(:user1)
  #  assert_no_difference('Manifestation.count') do
  #    post :create, :manifestation => { :original_title => 'test', :carrier_type_id => 1 }
  #  end
  #  
  #  assert_response :forbidden
  #end

  def test_user_should_not_create_manifestation
    sign_in users(:user1)
    assert_no_difference('Manifestation.count') do
      post :create, :manifestation => { :original_title => 'test', :carrier_type_id => 1 }
    end
    
    assert_response :forbidden
  end

  #def test_librarian_should_not_create_manifestation_without_expression
  #  sign_in users(:librarian1)
  #  old_count = Manifestation.count
  #  post :create, :manifestation => { :original_title => 'test', :carrier_type_id => 1, :language_id => 1 }
  #  assert_equal old_count, Manifestation.count
  #  
  #  assert_response :redirect
  #  assert_redirected_to expressions_url
  #  assert_equal 'Specify the expression.', flash[:notice]
  #end

  def test_librarian_should_create_manifestation_without_expression
    sign_in users(:librarian1)
    old_count = Manifestation.count
    post :create, :manifestation => { :original_title => 'test', :carrier_type_id => 1, :language_id => 1 }
    assert_equal old_count + 1, Manifestation.count
    
    assert_response :redirect
    assert assigns(:manifestation)
    assert assigns(:manifestation).embodies
    assert_redirected_to manifestation_url(assigns(:manifestation))
    assigns(:manifestation).remove_from_index!
  end

  def test_librarian_should_not_create_manifestation_without_title
    sign_in users(:librarian1)
    old_count = Manifestation.count
    post :create, :manifestation => { :carrier_type_id => 1, :language_id => 1 }, :expression_id => 1
    assert_equal old_count, Manifestation.count
    
    assert_response :success
  end

  def test_librarian_should_create_manifestation_with_expression
    sign_in users(:librarian1)
    old_count = Manifestation.count
    post :create, :manifestation => { :original_title => 'test', :carrier_type_id => 1, :language_id => 1 }, :expression_id => 1
    assert_equal old_count+1, Manifestation.count
    
    assert assigns(:expression)
    assert assigns(:manifestation)
    assert assigns(:manifestation).embodies
    assert_redirected_to manifestation_url(assigns(:manifestation))
    assigns(:manifestation).remove_from_index!
  end

  def test_admin_should_create_manifestation_with_expression
    sign_in users(:admin)
    old_count = Manifestation.count
    post :create, :manifestation => { :original_title => 'test', :carrier_type_id => 1, :language_id => 1 }, :expression_id => 1
    assert_equal old_count+1, Manifestation.count
    
    assert assigns(:expression)
    assert assigns(:manifestation)
    assert assigns(:manifestation).embodies
    assert_redirected_to manifestation_url(assigns(:manifestation))
    assigns(:manifestation).remove_from_index!
  end

  def test_guest_should_show_manifestation
    get :show, :id => 1
    assert_response :success
  end

  test 'guest shoud show manifestation screen shot' do
    get :show, :id => 22, :mode => 'screen_shot'
    assert_response :success
  end

  def test_guest_should_show_manifestation_with_holding
    get :show, :id => 1, :mode => 'holding'
    assert_response :success
  end

  def test_guest_should_show_manifestation_with_tag_edit
    get :show, :id => 1, :mode => 'tag_edit'
    assert_response :success
  end

  def test_guest_should_show_manifestation_with_tag_list
    get :show, :id => 1, :mode => 'tag_list'
    assert_response :success
  end

  def test_guest_should_show_manifestation_with_show_authors
    get :show, :id => 1, :mode => 'show_authors'
    assert_response :success
  end

  def test_guest_should_show_manifestation_with_show_all_authors
    get :show, :id => 1, :mode => 'show_all_authors'
    assert_response :success
  end

  def test_guest_should_show_manifestation_with_isbn
    get :show, :isbn => "4798002062"
    assert_response :redirect
    assert_redirected_to manifestation_url(assigns(:manifestation))
  end

  def test_guest_should_not_show_manifestation_with_invalid_isbn
    get :show, :isbn => "47980020620"
    assert_response :missing
  end

  def test_user_should_show_manifestation
    sign_in users(:user1)
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_manifestation
    sign_in users(:librarian1)
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_manifestation_with_expression_not_embodied
    sign_in users(:librarian1)
    get :show, :id => 1, :expression_id => 3
    assert_response :success
  end

  def test_librarian_should_show_manifestation_with_patron_not_produced
    sign_in users(:librarian1)
    get :show, :id => 3, :patron_id => 1
    assert_response :success
  end

  def test_admin_should_show_manifestation
    sign_in users(:admin)
    get :show, :id => 1
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_edit
    sign_in users(:user1)
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_user_should_get_edit_with_tag_edit
    sign_in users(:user1)
    get :edit, :id => 1, :mode => 'tag_edit'
    assert_response :success
  end
  
  def test_librarian_should_get_edit
    sign_in users(:librarian1)
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_librarian_should_get_edit_upload
    sign_in users(:librarian1)
    get :edit, :id => 1, :upload => true
    assert_response :success
  end
  
  def test_admin_should_get_edit
    sign_in users(:admin)
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_guest_should_not_update_manifestation
    put :update, :id => 1, :manifestation => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_manifestation
    sign_in users(:user1)
    put :update, :id => 1, :manifestation => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_manifestation_without_title
    sign_in users(:librarian1)
    put :update, :id => 1, :manifestation => { :original_title => nil }
    assert_response :success
  end
  
  def test_librarian_should_update_manifestation
    sign_in users(:librarian1)
    put :update, :id => 1, :manifestation => { }
    assert_redirected_to manifestation_url(assigns(:manifestation))
    assigns(:manifestation).remove_from_index!
  end
  
  def test_admin_should_update_manifestation
    sign_in users(:admin)
    put :update, :id => 1, :manifestation => { }
    assert_redirected_to manifestation_url(assigns(:manifestation))
    assigns(:manifestation).remove_from_index!
  end
  
  def test_guest_should_not_destroy_manifestation
    old_count = Manifestation.count
    delete :destroy, :id => 1
    assert_equal old_count, Manifestation.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_manifestation
    sign_in users(:user1)
    old_count = Manifestation.count
    delete :destroy, :id => 1
    assert_equal old_count, Manifestation.count
    
    assert_response :forbidden
  end

  def test_everyone_should_not_destroy_manifestation_contain_items
    sign_in users(:admin)
    assert_no_difference('Manifestation.count') do
      delete :destroy, :id => 1
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_destroy_manifestation
    sign_in users(:librarian1)
    assert_difference('Manifestation.count', -1) do
      delete :destroy, :id => 10
    end
    
    assert_redirected_to manifestations_url
  end

  def test_admin_should_destroy_manifestation
    sign_in users(:admin)
    assert_difference('Manifestation.count', -1) do
      delete :destroy, :id => 10
    end
    
    assert_redirected_to manifestations_url
  end
end
