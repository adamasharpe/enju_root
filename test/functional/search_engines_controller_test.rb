require 'test_helper'

class SearchEnginesControllerTest < ActionController::TestCase
  fixtures :search_engines, :library_groups, :users

  def test_guest_should_not_get_index
    get :index
    assert_response :redirect
    assert_redirected_to new_user_session_url
    assert_nil assigns(:search_engines)
  end

  def test_user_should_get_index
    login_as :user1
    get :index
    assert_response :forbidden
    assert_nil assigns(:search_engines)
  end

  def test_librarian_should_get_index
    login_as :librarian1
    get :index
    assert_response :success
  end

  def test_admin_should_get_index
    login_as :admin
    get :index
    assert_response :success
    assert assigns(:search_engines)
  end

  def test_guest_should_not_get_new
    get :new
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_new
    login_as :user1
    get :new
    assert_response :forbidden
  end
  
  def test_librarian_should_get_new
    login_as :librarian1
    get :new
    assert_response :forbidden
  end
  
  def test_admin_should_get_new
    login_as :admin
    get :new
    assert_response :success
  end
  
  def test_guest_should_not_create_search_engine
    old_count = SearchEngine.count
    post :create, :search_engine => { }
    assert_equal old_count, SearchEngine.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_search_engine
    login_as :user1
    old_count = SearchEngine.count
    post :create, :search_engine => { }
    assert_equal old_count, SearchEngine.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_search_engine
    login_as :librarian1
    old_count = SearchEngine.count
    post :create, :search_engine => { }
    assert_equal old_count, SearchEngine.count
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_search_engine_without_name
    login_as :admin
    old_count = SearchEngine.count
    post :create, :search_engine => { }
    assert_equal old_count, SearchEngine.count
    
    assert_response :success
  end

  def test_admin_should_create_search_engine
    login_as :admin
    old_count = SearchEngine.count
    post :create, :search_engine => {:name => 'test', :url => 'http://www.example.com/', :base_url => 'http://www.example.com/search', :http_method => 'get', :query_param => 'test'}
    assert_equal old_count+1, SearchEngine.count
    
    assert_redirected_to search_engine_url(assigns(:search_engine))
  end

  def test_guest_should_show_search_engine
    get :show, :id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_show_search_engine
    login_as :user1
    get :show, :id => 1
    assert_response :forbidden
  end

  def test_librarian_should_show_search_engine
    login_as :librarian1
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_search_engine
    login_as :admin
    get :show, :id => 1
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => 1
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_edit
    login_as :user1
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_librarian_should_not_get_edit
    login_as :librarian1
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_admin_should_get_edit
    login_as :admin
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_guest_should_not_update_search_engine
    put :update, :id => 1, :search_engine => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_search_engine
    login_as :user1
    put :update, :id => 1, :search_engine => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_search_engine
    login_as :librarian1
    put :update, :id => 1, :search_engine => { }
    assert_response :forbidden
  end
  
  def test_admin_should_not_update_search_engine_without_name
    login_as :admin
    put :update, :id => 1, :search_engine => {:name => ""}
    assert_response :success
  end
  
  def test_admin_should_update_search_engine
    login_as :admin
    put :update, :id => 1, :search_engine => {:name => 'test', :url => 'http://www.example.com/', :base_url => 'http://www.example.com/search', :http_method => 'get', :query_param => 'test'}
    assert_redirected_to search_engine_url(assigns(:search_engine))
  end
  
  def test_guest_should_not_destroy_search_engine
    old_count = SearchEngine.count
    delete :destroy, :id => 1
    assert_equal old_count, SearchEngine.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_search_engine
    login_as :user1
    old_count = SearchEngine.count
    delete :destroy, :id => 1
    assert_equal old_count, SearchEngine.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_search_engine
    login_as :librarian1
    old_count = SearchEngine.count
    delete :destroy, :id => 1
    assert_equal old_count, SearchEngine.count
    
    assert_response :forbidden
  end

  def test_admin_should_destroy_search_engine
    login_as :admin
    old_count = SearchEngine.count
    delete :destroy, :id => 1
    assert_equal old_count-1, SearchEngine.count
    
    assert_redirected_to search_engines_url
  end
end
