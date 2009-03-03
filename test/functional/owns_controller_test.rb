require 'test_helper'

class OwnsControllerTest < ActionController::TestCase
  fixtures :owns, :users, :manifestations, :patrons
  fixtures :people, :corporate_bodies, :families

  def test_guest_should_get_index
    get :index
    assert_response :success
    assert assigns(:owns)
  end

  def test_user_should_get_index
    login_as :user1
    get :index
    assert_response :success
    assert assigns(:owns)
  end

  def test_user_should_get_index_with_patron_id
    login_as :user1
    get :index, :patron_id => 1
    assert_response :success
    assert assigns(:owns)
  end

  def test_user_should_get_index_with_item_id
    login_as :user1
    get :index, :item_id => 1
    assert_response :success
    assert assigns(:owns)
  end

  def test_librarian_should_get_index
    login_as :librarian1
    get :index
    assert_response :success
    assert assigns(:owns)
  end

  def test_guest_should_not_get_new
    get :new
    assert_response :redirect
    assert_redirected_to new_session_url
  end
  
  def test_user_should_not_get_new
    login_as :user1
    get :new
    assert_response :forbidden
  end
  
  def test_librarian_should_get_new_with_login
    login_as :librarian1
    get :new
    assert_response :success
  end
  
  def test_guest_should_not_create_own
    old_count = Own.count
    post :create, :own => {:patron_id => 1, :item_id => 1}
    assert_equal old_count, Own.count
    
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  def test_user_should_not_create_own
    login_as :user1
    old_count = Own.count
    post :create, :own => {:patron_id => 1, :item_id => 1}
    assert_equal old_count, Own.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_own_without_patron_id
    login_as :librarian1
    old_count = Own.count
    post :create, :own => {:item_id => 1}
    assert_equal old_count, Own.count
    
    assert_response :success
  end

  def test_librarian_should_not_create_own_without_item_id
    login_as :librarian1
    old_count = Own.count
    post :create, :own => {:patron_id => 1}
    assert_equal old_count, Own.count
    
    assert_response :success
  end

  def test_librarian_should_create_own
    login_as :librarian1
    old_count = Own.count
    post :create, :own => {:patron_id => 1, :patron_type => 'Person', :item_id => 3}
    assert_equal old_count+1, Own.count
    
    assert_redirected_to own_url(assigns(:own))
  end

  def test_guest_should_show_own
    get :show, :id => 1
    assert_response :success
  end

  def test_user_should_show_own
    login_as :user1
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_own
    login_as :librarian1
    get :show, :id => 1
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => 1
    assert_response :redirect
    assert_redirected_to new_session_url
  end
  
  def test_user_should_not_get_edit
    login_as :user1
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_librarian_should_get_edit
    login_as :librarian1
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_guest_should_not_update_own
    put :update, :id => 1, :own => { }
    assert_response :redirect
    assert_redirected_to new_session_url
  end
  
  def test_user_should_not_update_own
    login_as :user1
    put :update, :id => 1, :own => { }
    assert_response :forbidden
  end

  def test_librarian_should_not_update_own_without_patron_id
    login_as :librarian1
    put :update, :id => 1, :own => {:patron_id => nil}
    assert_response :success
  end
  
  def test_librarian_should_not_update_own_without_item_id
    login_as :librarian1
    put :update, :id => 1, :own => {:item_id => nil}
    assert_response :success
  end
  
  def test_librarian_should_update_own
    login_as :librarian1
    put :update, :id => 1, :own => { }
    assert_redirected_to own_url(assigns(:own))
  end
  
  def test_guest_should_not_destroy_own
    old_count = Own.count
    delete :destroy, :id => 1
    assert_equal old_count, Own.count
    
    assert_response :redirect
    assert_redirected_to new_session_url
  end
  
  def test_user_should_not_destroy_own
    login_as :user1
    old_count = Own.count
    delete :destroy, :id => 1
    assert_equal old_count, Own.count
    
    assert_response :forbidden
  end
  
  def test_librarian_should_destroy_own
    login_as :librarian1
    old_count = Own.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Own.count
    
    assert_redirected_to owns_url
  end
end
