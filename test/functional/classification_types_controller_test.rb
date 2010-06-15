require 'test_helper'

class ClassificationTypesControllerTest < ActionController::TestCase
  fixtures :classification_types, :users

  def test_guest_should_not_get_index
    get :index
    assert_response :success
    assert assigns(:classification_types)
  end

  def test_user_should_get_index
    sign_in users(:user1)
    get :index
    assert_response :success
    assert assigns(:classification_types)
  end

  def test_librarian_should_get_index
    sign_in users(:librarian1)
    get :index
    assert_response :success
    assert assigns(:classification_types)
  end

  def test_admin_should_get_index
    sign_in users(:admin)
    get :index
    assert_response :success
    assert assigns(:classification_types)
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
  
  def test_guest_should_not_create_classification_type
    old_count = ClassificationType.count
    post :create, :classification_type => { }
    assert_equal old_count, ClassificationType.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_classification_type
    sign_in users(:user1)
    old_count = ClassificationType.count
    post :create, :classification_type => { }
    assert_equal old_count, ClassificationType.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_classification_type
    sign_in users(:librarian1)
    old_count = ClassificationType.count
    post :create, :classification_type => { }
    assert_equal old_count, ClassificationType.count
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_classification_type_without_name
    sign_in users(:admin)
    old_count = ClassificationType.count
    post :create, :classification_type => { }
    assert_equal old_count, ClassificationType.count
    
    assert_response :success
  end

  def test_admin_should_create_classification_type
    sign_in users(:admin)
    old_count = ClassificationType.count
    post :create, :classification_type => {:name => 'test'}
    assert_equal old_count+1, ClassificationType.count
    assert 'test', assigns(:classification_type).display_name
    
    assert_redirected_to classification_type_url(assigns(:classification_type))
  end

  def test_guest_should_show_classification_type
    get :show, :id => 1
    assert_response :success
  end

  def test_user_should_show_classification_type
    sign_in users(:user1)
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_classification_type
    sign_in users(:librarian1)
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_classification_type
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
  
  def test_guest_should_not_update_classification_type
    put :update, :id => 1, :classification_type => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_classification_type
    sign_in users(:user1)
    put :update, :id => 1, :classification_type => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_classification_type
    sign_in users(:librarian1)
    put :update, :id => 1, :classification_type => { }
    assert_response :forbidden
  end
  
  def test_admin_should_update_classification_type_without_name
    sign_in users(:admin)
    put :update, :id => 1, :classification_type => {:name => ""}
    assert_response :success
  end
  
  def test_admin_should_update_classification_type
    sign_in users(:admin)
    put :update, :id => 1, :classification_type => { }
    assert_redirected_to classification_type_url(assigns(:classification_type))
  end
  
  def test_guest_should_not_destroy_classification_type
    old_count = ClassificationType.count
    delete :destroy, :id => 1
    assert_equal old_count, ClassificationType.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_classification_type
    sign_in users(:user1)
    old_count = ClassificationType.count
    delete :destroy, :id => 1
    assert_equal old_count, ClassificationType.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_classification_type
    sign_in users(:librarian1)
    old_count = ClassificationType.count
    delete :destroy, :id => 1
    assert_equal old_count, ClassificationType.count
    
    assert_response :forbidden
  end

  def test_admin_should_destroy_classification_type
    sign_in users(:admin)
    old_count = ClassificationType.count
    delete :destroy, :id => 1
    assert_equal old_count-1, ClassificationType.count
    
    assert_redirected_to classification_types_url
  end
end
