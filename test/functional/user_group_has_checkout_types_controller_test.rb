require 'test_helper'

class UserGroupHasCheckoutTypesControllerTest < ActionController::TestCase
  fixtures :user_group_has_checkout_types, :users, :user_groups, :checkout_types

  def test_guest_should_not_get_index
    get :index
    assert_response :redirect
    assert_redirected_to new_session_url
    assert_nil assigns(:user_group_has_checkout_types)
  end

  def test_user_should_not_get_index
    login_as :user1
    get :index
    assert_response :forbidden
    assert_nil assigns(:user_group_has_checkout_types)
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
    assert assigns(:user_group_has_checkout_types)
  end

  def test_guest_should_not_get_new
    get :new
    assert_redirected_to new_session_url
  end
  
  def test_user_should_not_get_new
    login_as :user1
    get :new
    assert_response :forbidden
  end
  
  def test_librarian_should_not_get_new
    login_as :librarian1
    get :new
    assert_response :forbidden
  end
  
  def test_admin_should_get_new
    login_as :admin
    get :new
    assert_response :success
  end
  
  def test_guest_should_not_create_user_group_has_checkout_type
    old_count = UserGroupHasCheckoutType.count
    post :create, :user_group_has_checkout_type => { }
    assert_equal old_count, UserGroupHasCheckoutType.count
    
    assert_redirected_to new_session_url
  end

  def test_user_should_not_create_user_group_has_checkout_type
    login_as :user1
    old_count = UserGroupHasCheckoutType.count
    post :create, :user_group_has_checkout_type => { }
    assert_equal old_count, UserGroupHasCheckoutType.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_user_group_has_checkout_type
    login_as :librarian1
    old_count = UserGroupHasCheckoutType.count
    post :create, :user_group_has_checkout_type => { }
    assert_equal old_count, UserGroupHasCheckoutType.count
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_user_group_has_checkout_type_already_created
    login_as :admin
    old_count = UserGroupHasCheckoutType.count
    post :create, :user_group_has_checkout_type => {:user_group_id => 1, :checkout_type_id => 1}
    assert_equal old_count, UserGroupHasCheckoutType.count
    
    assert_response :success
  end

  def test_admin_should_create_user_group_has_checkout_type
    login_as :admin
    old_count = UserGroupHasCheckoutType.count
    post :create, :user_group_has_checkout_type => {:user_group_id => 3, :checkout_type_id => 3}
    assert_equal old_count+1, UserGroupHasCheckoutType.count
    
    assert_redirected_to user_group_has_checkout_type_url(assigns(:user_group_has_checkout_type))
  end

  def test_guest_should_not_show_user_group_has_checkout_type
    get :show, :id => 1
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  def test_user_should_not_show_user_group_has_checkout_type
    login_as :user1
    get :show, :id => 1
    assert_response :forbidden
  end

  def test_librarian_should_show_user_group_has_checkout_type
    login_as :librarian1
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_user_group_has_checkout_type
    login_as :admin
    get :show, :id => 1
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => 1
    assert_redirected_to new_session_url
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
  
  def test_guest_should_not_update_user_group_has_checkout_type
    put :update, :id => 1, :user_group_has_checkout_type => { }
    assert_redirected_to new_session_url
  end
  
  def test_user_should_not_update_user_group_has_checkout_type
    login_as :user1
    put :update, :id => 1, :user_group_has_checkout_type => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_user_group_has_checkout_type
    login_as :librarian1
    put :update, :id => 1, :user_group_has_checkout_type => { }
    assert_response :forbidden
  end
  
  def test_admin_should_update_user_group_has_checkout_type
    login_as :admin
    put :update, :id => 1, :user_group_has_checkout_type => { }
    assert_redirected_to user_group_has_checkout_type_url(assigns(:user_group_has_checkout_type))
  end
  
  def test_guest_should_not_destroy_user_group_has_checkout_type
    old_count = UserGroupHasCheckoutType.count
    delete :destroy, :id => 1
    assert_equal old_count, UserGroupHasCheckoutType.count
    
    assert_redirected_to new_session_url
  end

  def test_user_should_not_destroy_user_group_has_checkout_type
    login_as :user1
    old_count = UserGroupHasCheckoutType.count
    delete :destroy, :id => 1
    assert_equal old_count, UserGroupHasCheckoutType.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_user_group_has_checkout_type
    login_as :librarian1
    old_count = UserGroupHasCheckoutType.count
    delete :destroy, :id => 1
    assert_equal old_count, UserGroupHasCheckoutType.count
    
    assert_response :forbidden
  end

  def test_admin_should_destroy_user_group_has_checkout_type
    login_as :admin
    old_count = UserGroupHasCheckoutType.count
    delete :destroy, :id => 1
    assert_equal old_count-1, UserGroupHasCheckoutType.count
    
    assert_redirected_to user_group_has_checkout_types_url
  end
end
