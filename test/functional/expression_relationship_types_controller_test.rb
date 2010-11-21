require 'test_helper'

class ExpressionRelationshipTypesControllerTest < ActionController::TestCase
    fixtures :expression_relationship_types, :users

  def test_guest_should_get_index
    get :index
    assert_response :success
    assert assigns(:expression_relationship_types)
  end

  def test_user_should_get_index
    sign_in users(:user1)
    get :index
    assert_response :success
    assert assigns(:expression_relationship_types)
  end

  def test_librarian_should_get_index
    sign_in users(:librarian1)
    get :index
    assert_response :success
    assert assigns(:expression_relationship_types)
  end

  def test_admin_should_get_index
    sign_in users(:admin)
    get :index
    assert_response :success
    assert assigns(:expression_relationship_types)
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
  
  def test_librarian_should_not_get_new
    sign_in users(:librarian1)
    get :new
    assert_response :forbidden
  end
  
  def test_admin_should_not_get_new
    sign_in users(:admin)
    get :new
    assert_response :forbidden
  end
  
  def test_guest_should_not_create_expression_relationship_type
    assert_no_difference('ExpressionRelationshipType.count') do
      post :create, :expression_relationship_type => { }
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_expression_relationship_type
    sign_in users(:user1)
    assert_no_difference('ExpressionRelationshipType.count') do
      post :create, :expression_relationship_type => { }
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_expression_relationship_type
    sign_in users(:librarian1)
    assert_no_difference('ExpressionRelationshipType.count') do
      post :create, :expression_relationship_type => { }
    end
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_expression_relationship_type
    sign_in users(:admin)
    assert_no_difference('ExpressionRelationshipType.count') do
      post :create, :expression_relationship_type => {:name => 'test', :display_name => 'test'}
    end
    
    assert_response :forbidden
  end

  def test_guest_should_show_expression_relationship_type
    get :show, :id => 1
    assert_response :success
  end

  def test_user_should_show_expression_relationship_type
    sign_in users(:user1)
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_expression_relationship_type
    sign_in users(:librarian1)
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_expression_relationship_type
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
  
  def test_guest_should_not_update_expression_relationship_type
    put :update, :id => 1, :expression_relationship_type => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_expression_relationship_type
    sign_in users(:user1)
    put :update, :id => 1, :expression_relationship_type => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_expression_relationship_type
    sign_in users(:librarian1)
    put :update, :id => 1, :expression_relationship_type => { }
    assert_response :forbidden
  end
  
  def test_admin_should_update_expression_relationship_type_without_name
    sign_in users(:admin)
    put :update, :id => 1, :expression_relationship_type => {:name => ""}
    assert_response :success
  end
  
  def test_admin_should_update_expression_relationship_type
    sign_in users(:admin)
    put :update, :id => 1, :expression_relationship_type => { }
    assert_redirected_to expression_relationship_type_url(assigns(:expression_relationship_type))
  end
  
  test "admin should update expression_relationship_type with position" do
    sign_in users(:admin)
    put :update, :id => expression_relationship_types(:expression_relationship_type_00001), :expression_relationship_type => { }, :position => 2
    assert_redirected_to expression_relationship_types_path
  end

  def test_guest_should_not_destroy_expression_relationship_type
    old_count = ExpressionRelationshipType.count
    delete :destroy, :id => 1
    assert_equal old_count, ExpressionRelationshipType.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_expression_relationship_type
    sign_in users(:user1)
    assert_no_difference('ExpressionRelationshipType.count') do
      delete :destroy, :id => 1
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_expression_relationship_type
    sign_in users(:librarian1)
    assert_no_difference('ExpressionRelationshipType.count') do
      delete :destroy, :id => 1
    end
    
    assert_response :forbidden
  end

  def test_admin_should_not_destroy_expression_relationship_type
    sign_in users(:admin)
    assert_no_difference('ExpressionRelationshipType.count', -1) do
      delete :destroy, :id => 1
    end
    
    assert_response :forbidden
  end
end
