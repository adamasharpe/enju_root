require 'test_helper'

class UserGroupsControllerTest < ActionController::TestCase
  fixtures :user_groups, :users

  def test_guest_should_get_index
    get :index
    assert_response :success
    assert assigns(:user_groups)
  end

  def test_user_should_get_index
    sign_in users(:user1)
    get :index
    assert_response :success
    assert assigns(:user_groups)
  end

  def test_librarian_should_get_index
    sign_in users(:librarian1)
    get :index
    assert_response :success
    assert assigns(:user_groups)
  end

  def test_admin_should_get_index
    sign_in users(:admin)
    get :index
    assert_response :success
    assert assigns(:user_groups)
  end

  def test_guest_should_not_get_new
    get :new
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_new
    sign_in users(:user1)
    get :new
    assert_response :forbidden
  end
  
  def test_librarian_should_get_new
    sign_in users(:librarian1)
    get :new
    assert_response :forbidden
  end
  
  def test_admin_should_get_new
    sign_in users(:admin)
    get :new
    assert_response :success
  end
  
  def test_guest_should_not_create_user_group
    assert_no_difference('UserGroup.count') do
      post :create, :user_group => { }
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_user_group
    sign_in users(:user1)
    assert_no_difference('UserGroup.count') do
      post :create, :user_group => { }
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_user_group
    sign_in users(:librarian1)
    assert_no_difference('UserGroup.count') do
      post :create, :user_group => { }
    end
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_user_group_without_name
    sign_in users(:admin)
    assert_no_difference('UserGroup.count') do
      post :create, :user_group => { }
    end
    
    assert_response :success
  end

  def test_admin_should_create_user_group
    sign_in users(:admin)
    assert_difference('UserGroup.count') do
      post :create, :user_group => {:name => 'test'}
    end
    
    assert_redirected_to user_group_url(assigns(:user_group))
  end

  #def test_admin_should_create_user_group_with_library_id
  #  sign_in users(:admin)
  #  assert_difference('UserGroup.count') do
  #   post :create, :user_group => {:name => 'test'}, :library_id => 1
  #  end
  #  
  #  assert assigns(:library)
  #  assert_redirected_to user_group_url(assigns(:user_group))
  #end

  def test_guest_should_show_user_group
    get :show, :id => 1
    assert_response :success
  end

  def test_user_should_show_user_group
    sign_in users(:user1)
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_user_group
    sign_in users(:librarian1)
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_user_group
    sign_in users(:admin)
    get :show, :id => 1
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => 1
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_edit
    sign_in users(:user1)
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_librarian_should_not_get_edit
    sign_in users(:librarian1)
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_admin_should_get_edit
    sign_in users(:admin)
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_guest_should_not_update_user_group
    put :update, :id => 1, :user_group => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_user_group
    sign_in users(:user1)
    put :update, :id => 1, :user_group => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_user_group
    sign_in users(:librarian1)
    put :update, :id => 1, :user_group => { }
    assert_response :forbidden
  end
  
  def test_admin_should_not_update_user_group_without_name
    sign_in users(:admin)
    put :update, :id => 1, :user_group => {:name => ""}
    assert_response :success
  end
  
  def test_admin_should_update_user_group
    sign_in users(:admin)
    put :update, :id => 1, :user_group => { }
    assert_redirected_to user_group_url(assigns(:user_group))
  end
  
  def test_guest_should_not_destroy_user_group
    assert_no_difference('UserGroup.count') do
      delete :destroy, :id => 1
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_user_group
    sign_in users(:user1)
    assert_no_difference('UserGroup.count') do
      delete :destroy, :id => 1
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_user_group
    sign_in users(:librarian1)
    assert_no_difference('UserGroup.count') do
      delete :destroy, :id => 1
    end
    
    assert_response :forbidden
  end

  def test_admin_should_not_destroy_user_group_contains_users
    sign_in users(:admin)
    assert_no_difference('UserGroup.count') do
      delete :destroy, :id => 1
    end

    assert_response :forbidden
  end

  def test_admin_should_destroy_user_group_not_contains_users
    sign_in users(:admin)
    assert_difference('UserGroup.count', -1) do
      delete :destroy, :id => 3
    end
    
    assert_redirected_to user_groups_url
  end
end
