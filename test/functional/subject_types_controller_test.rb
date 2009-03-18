require 'test_helper'

class SubjectTypesControllerTest < ActionController::TestCase
  fixtures :subject_types, :users

  def test_guest_should_not_get_index
    get :index
    assert_response :redirect
    assert_redirected_to new_user_session_url
    assert_nil assigns(:subject_types)
  end

  def test_user_should_get_index
    login_as :user1
    get :index
    assert_response :forbidden
    assert_nil assigns(:subject_types)
  end

  def test_librarian_should_get_index
    login_as :librarian1
    get :index
    assert_response :success
    assert assigns(:subject_types)
  end

  def test_admin_should_get_index
    login_as :admin
    get :index
    assert_response :success
    assert assigns(:subject_types)
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
  
  def test_guest_should_not_create_subject_type
    assert_no_difference('SubjectType.count') do
      post :create, :subject_type => { }
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_subject_type
    login_as :user1
    assert_no_difference('SubjectType.count') do
      post :create, :subject_type => { }
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_subject_type
    login_as :librarian1
    assert_no_difference('SubjectType.count') do
      post :create, :subject_type => { }
    end
    post :create, :subject_type => { }
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_subject_type_without_name
    login_as :admin
    assert_no_difference('SubjectType.count') do
      post :create, :subject_type => { }
    end
    
    assert_response :success
  end

  def test_admin_should_create_subject_type
    login_as :admin
    assert_difference('SubjectType.count') do
      post :create, :subject_type => {:name => 'test'}
    end
    
    assert_redirected_to subject_type_url(assigns(:subject_type))
  end

  def test_guest_should_not_show_subject_type
    get :show, :id => subject_types(:subject_type_00001)
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_show_subject_type
    login_as :user1
    get :show, :id => subject_types(:subject_type_00001)
    assert_response :forbidden
  end

  def test_librarian_should_show_subject_type
    login_as :librarian1
    get :show, :id => subject_types(:subject_type_00001)
    assert_response :success
  end

  def test_admin_should_show_subject_type
    login_as :admin
    get :show, :id => subject_types(:subject_type_00001)
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => subject_types(:subject_type_00001)
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_edit
    login_as :user1
    get :edit, :id => subject_types(:subject_type_00001)
    assert_response :forbidden
  end
  
  def test_librarian_should_not_get_edit
    login_as :librarian1
    get :edit, :id => subject_types(:subject_type_00001)
    assert_response :forbidden
  end
  
  def test_admin_should_get_edit
    login_as :admin
    get :edit, :id => subject_types(:subject_type_00001)
    assert_response :success
  end
  
  def test_guest_should_not_update_subject_type
    put :update, :id => subject_types(:subject_type_00001), :subject_type => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_subject_type
    login_as :user1
    put :update, :id => subject_types(:subject_type_00001), :subject_type => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_subject_type
    login_as :librarian1
    put :update, :id => subject_types(:subject_type_00001), :subject_type => { }
    assert_response :forbidden
  end
  
  def test_admin_should_update_subject_type_without_name
    login_as :admin
    put :update, :id => subject_types(:subject_type_00001), :subject_type => {:name => ""}
    assert_response :success
  end
  
  def test_admin_should_update_subject_type
    login_as :admin
    put :update, :id => subject_types(:subject_type_00001), :subject_type => { }
    assert_redirected_to subject_type_url(assigns(:subject_type))
  end
  
  def test_guest_should_not_destroy_subject_type
    assert_no_difference('SubjectType.count') do
      delete :destroy, :id => subject_types(:subject_type_00001)
    end
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_subject_type
    login_as :user1
    assert_no_difference('SubjectType.count') do
      delete :destroy, :id => subject_types(:subject_type_00001)
    end
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_subject_type
    login_as :librarian1
    assert_no_difference('SubjectType.count') do
      delete :destroy, :id => subject_types(:subject_type_00001)
    end
    
    assert_response :forbidden
  end

  def test_admin_should_destroy_subject_type
    login_as :admin
    assert_difference('SubjectType.count', -1) do
      delete :destroy, :id => subject_types(:subject_type_00001)
    end
    
    assert_redirected_to subject_types_url
  end
end
