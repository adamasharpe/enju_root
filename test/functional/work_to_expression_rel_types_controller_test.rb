require 'test_helper'

class WorkToExpressionRelTypesControllerTest < ActionController::TestCase
    fixtures :work_to_expression_rel_types, :users

  def test_guest_should_get_index
    get :index
    assert_response :success
    assert assigns(:work_to_expression_rel_types)
  end

  def test_user_should_get_index
    sign_in users(:user1)
    get :index
    assert_response :success
    assert assigns(:work_to_expression_rel_types)
  end

  def test_librarian_should_get_index
    sign_in users(:librarian1)
    get :index
    assert_response :success
    assert assigns(:work_to_expression_rel_types)
  end

  def test_admin_should_get_index
    sign_in users(:admin)
    get :index
    assert_response :success
    assert assigns(:work_to_expression_rel_types)
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
  
  def test_guest_should_not_create_work_to_expression_rel_type
    assert_no_difference('WorkToExpressionRelType.count') do
      post :create, :work_to_expression_rel_type => { }
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_work_to_expression_rel_type
    sign_in users(:user1)
    assert_no_difference('WorkToExpressionRelType.count') do
      post :create, :work_to_expression_rel_type => { }
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_work_to_expression_rel_type
    sign_in users(:librarian1)
    assert_no_difference('WorkToExpressionRelType.count') do
      post :create, :work_to_expression_rel_type => { }
    end
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_work_to_expression_rel_type_without_name
    sign_in users(:admin)
    assert_no_difference('WorkToExpressionRelType.count') do
      post :create, :work_to_expression_rel_type => { }
    end
    
    assert_response :success
  end

  def test_admin_should_create_work_to_expression_rel_type
    sign_in users(:admin)
    assert_difference('WorkToExpressionRelType.count') do
      post :create, :work_to_expression_rel_type => {:name => 'test', :display_name => 'test'}
    end
    
    assert_redirected_to work_to_expression_rel_type_url(assigns(:work_to_expression_rel_type))
  end

  def test_guest_should_show_work_to_expression_rel_type
    get :show, :id => 1
    assert_response :success
  end

  def test_user_should_show_work_to_expression_rel_type
    sign_in users(:user1)
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_work_to_expression_rel_type
    sign_in users(:librarian1)
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_work_to_expression_rel_type
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
  
  def test_guest_should_not_update_work_to_expression_rel_type
    put :update, :id => 1, :work_to_expression_rel_type => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_work_to_expression_rel_type
    sign_in users(:user1)
    put :update, :id => 1, :work_to_expression_rel_type => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_work_to_expression_rel_type
    sign_in users(:librarian1)
    put :update, :id => 1, :work_to_expression_rel_type => { }
    assert_response :forbidden
  end
  
  def test_admin_should_update_work_to_expression_rel_type_without_name
    sign_in users(:admin)
    put :update, :id => 1, :work_to_expression_rel_type => {:name => ""}
    assert_response :success
  end
  
  def test_admin_should_update_work_to_expression_rel_type
    sign_in users(:admin)
    put :update, :id => 1, :work_to_expression_rel_type => { }
    assert_redirected_to work_to_expression_rel_type_url(assigns(:work_to_expression_rel_type))
  end
  
  def test_admin_should_update_work_to_expression_rel_type_with_position
    sign_in users(:admin)
    put :update, :id => 1, :work_to_expression_rel_type => { }, :position => 2
    assert_redirected_to work_to_expression_rel_types_url
  end

  def test_guest_should_not_destroy_work_to_expression_rel_type
    assert_no_difference('WorkToExpressionRelType.count') do
      delete :destroy, :id => 1
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_work_to_expression_rel_type
    sign_in users(:user1)
    assert_no_difference('WorkToExpressionRelType.count') do
      delete :destroy, :id => 1
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_work_to_expression_rel_type
    sign_in users(:librarian1)
    assert_no_difference('WorkToExpressionRelType.count') do
      delete :destroy, :id => 1
    end
    
    assert_response :forbidden
  end

  def test_admin_should_destroy_work_to_expression_rel_type
    sign_in users(:admin)
    assert_difference('WorkToExpressionRelType.count', -1) do
      delete :destroy, :id => 1
    end
    
    assert_redirected_to work_to_expression_rel_types_url
  end
end
