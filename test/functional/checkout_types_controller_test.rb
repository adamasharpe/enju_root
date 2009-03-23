require 'test_helper'

class CheckoutTypesControllerTest < ActionController::TestCase
  fixtures :checkout_types, :users

  def test_guest_should_not_get_index
    get :index
    assert_response :redirect
    assert_redirected_to new_user_session_url
    assert_nil assigns(:checkout_types)
  end

  def test_user_should_get_index
    set_session_for users(:user1)
    get :index
    assert_response :forbidden
    assert_nil assigns(:checkout_types)
  end

  def test_librarian_should_get_index
    set_session_for users(:librarian1)
    get :index
    assert_response :success
    assert assigns(:checkout_types)
  end

  def test_admin_should_get_index
    set_session_for users(:admin)
    get :index
    assert_response :success
    assert assigns(:checkout_types)
  end

  def test_guest_should_not_get_new
    get :new
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_new
    set_session_for users(:user1)
    get :new
    assert_response :forbidden
  end
  
  def test_librarian_should_get_new
    set_session_for users(:librarian1)
    get :new
    assert_response :forbidden
  end
  
  def test_admin_should_get_new
    set_session_for users(:admin)
    get :new
    assert_response :success
  end
  
  def test_guest_should_not_create_checkout_type
    assert_no_difference('CheckoutType.count') do
      post :create, :checkout_type => { }
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_checkout_type
    set_session_for users(:user1)
    assert_no_difference('CheckoutType.count') do
      post :create, :checkout_type => { }
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_checkout_type
    set_session_for users(:librarian1)
    assert_no_difference('CheckoutType.count') do
      post :create, :checkout_type => { }
    end
    post :create, :checkout_type => { }
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_checkout_type_without_name
    set_session_for users(:admin)
    assert_no_difference('CheckoutType.count') do
      post :create, :checkout_type => { }
    end
    
    assert_response :success
  end

  def test_admin_should_create_checkout_type
    set_session_for users(:admin)
    assert_difference('CheckoutType.count') do
      post :create, :checkout_type => {:name => 'test'}
    end
    
    assert_redirected_to checkout_type_url(assigns(:checkout_type))
  end

  def test_guest_should_not_show_checkout_type
    get :show, :id => checkout_types(:checkout_type_00001)
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_show_checkout_type
    set_session_for users(:user1)
    get :show, :id => checkout_types(:checkout_type_00001)
    assert_response :forbidden
  end

  def test_librarian_should_show_checkout_type
    set_session_for users(:librarian1)
    get :show, :id => checkout_types(:checkout_type_00001)
    assert_response :success
  end

  def test_admin_should_show_checkout_type
    set_session_for users(:admin)
    get :show, :id => checkout_types(:checkout_type_00001)
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => checkout_types(:checkout_type_00001)
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_edit
    set_session_for users(:user1)
    get :edit, :id => checkout_types(:checkout_type_00001)
    assert_response :forbidden
  end
  
  def test_librarian_should_not_get_edit
    set_session_for users(:librarian1)
    get :edit, :id => checkout_types(:checkout_type_00001)
    assert_response :forbidden
  end
  
  def test_admin_should_get_edit
    set_session_for users(:admin)
    get :edit, :id => checkout_types(:checkout_type_00001)
    assert_response :success
  end
  
  def test_guest_should_not_update_checkout_type
    put :update, :id => checkout_types(:checkout_type_00001), :checkout_type => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_checkout_type
    set_session_for users(:user1)
    put :update, :id => checkout_types(:checkout_type_00001), :checkout_type => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_checkout_type
    set_session_for users(:librarian1)
    put :update, :id => checkout_types(:checkout_type_00001), :checkout_type => { }
    assert_response :forbidden
  end
  
  def test_admin_should_update_checkout_type_without_name
    set_session_for users(:admin)
    put :update, :id => checkout_types(:checkout_type_00001), :checkout_type => {:name => ""}
    assert_response :success
  end
  
  def test_admin_should_update_checkout_type
    set_session_for users(:admin)
    put :update, :id => checkout_types(:checkout_type_00001), :checkout_type => { }
    assert_redirected_to checkout_type_url(assigns(:checkout_type))
  end
  
  def test_guest_should_not_destroy_checkout_type
    assert_no_difference('CheckoutType.count') do
      delete :destroy, :id => checkout_types(:checkout_type_00001)
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_checkout_type
    set_session_for users(:user1)
    assert_no_difference('CheckoutType.count') do
      delete :destroy, :id => checkout_types(:checkout_type_00001)
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_checkout_type
    set_session_for users(:librarian1)
    assert_no_difference('CheckoutType.count') do
      delete :destroy, :id => checkout_types(:checkout_type_00001)
    end
    
    assert_response :forbidden
  end

  def test_admin_should_destroy_checkout_type
    set_session_for users(:admin)
    assert_difference('CheckoutType.count', -1) do
      delete :destroy, :id => checkout_types(:checkout_type_00001)
    end
    
    assert_redirected_to checkout_types_url
  end
end
