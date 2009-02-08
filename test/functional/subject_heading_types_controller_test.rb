require File.dirname(__FILE__) + '/../test_helper'
require 'subject_heading_types_controller'

class SubjectTypesControllerTest < ActionController::TestCase
  fixtures :subject_heading_types, :users

  def test_guest_should_not_get_index
    get :index
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  def test_user_should_get_index
    login_as :user1
    get :index
    assert_response :success
    assert assigns(:subject_heading_types)
  end

  def test_librarian_should_get_index
    login_as :librarian1
    get :index
    assert_response :success
    assert assigns(:subject_heading_types)
  end

  def test_admin_should_get_index
    login_as :admin
    get :index
    assert_response :success
    assert assigns(:subject_heading_types)
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
  
  def test_guest_should_not_create_subject_heading_type
    old_count = SubjectType.count
    post :create, :subject_heading_type => { }
    assert_equal old_count, SubjectType.count
    
    assert_redirected_to new_session_url
  end

  def test_user_should_not_create_subject_heading_type
    login_as :user1
    old_count = SubjectType.count
    post :create, :subject_heading_type => { }
    assert_equal old_count, SubjectType.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_subject_heading_type
    login_as :librarian1
    old_count = SubjectType.count
    post :create, :subject_heading_type => { }
    assert_equal old_count, SubjectType.count
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_subject_heading_type_without_name
    login_as :admin
    old_count = SubjectType.count
    post :create, :subject_heading_type => { }
    assert_equal old_count, SubjectType.count
    
    assert_response :success
  end

  def test_admin_should_create_subject_heading_type
    login_as :admin
    old_count = SubjectType.count
    post :create, :subject_heading_type => {:name => 'test'}
    assert_equal old_count+1, SubjectType.count
    
    assert_redirected_to subject_heading_type_url(assigns(:subject_heading_type))
  end

  def test_guest_should_show_subject_heading_type
    get :show, :id => 1
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  def test_user_should_show_subject_heading_type
    login_as :user1
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_subject_heading_type
    login_as :librarian1
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_subject_heading_type
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
  
  def test_guest_should_not_update_subject_heading_type
    put :update, :id => 1, :subject_heading_type => { }
    assert_redirected_to new_session_url
  end
  
  def test_user_should_not_update_subject_heading_type
    login_as :user1
    put :update, :id => 1, :subject_heading_type => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_subject_heading_type
    login_as :librarian1
    put :update, :id => 1, :subject_heading_type => { }
    assert_response :forbidden
  end
  
  def test_admin_should_update_subject_heading_type_without_name
    login_as :admin
    put :update, :id => 1, :subject_heading_type => {:name => ""}
    assert_response :success
  end
  
  def test_admin_should_update_subject_heading_type
    login_as :admin
    put :update, :id => 1, :subject_heading_type => { }
    assert_redirected_to subject_heading_type_url(assigns(:subject_heading_type))
  end
  
  def test_guest_should_not_destroy_subject_heading_type
    old_count = SubjectType.count
    delete :destroy, :id => 1
    assert_equal old_count, SubjectType.count
    
    assert_redirected_to new_session_url
  end

  def test_user_should_not_destroy_subject_heading_type
    login_as :user1
    old_count = SubjectType.count
    delete :destroy, :id => 1
    assert_equal old_count, SubjectType.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_subject_heading_type
    login_as :librarian1
    old_count = SubjectType.count
    delete :destroy, :id => 1
    assert_equal old_count, SubjectType.count
    
    assert_response :forbidden
  end

  def test_admin_should_destroy_subject_heading_type
    login_as :admin
    old_count = SubjectType.count
    delete :destroy, :id => 1
    assert_equal old_count-1, SubjectType.count
    
    assert_redirected_to subject_heading_types_url
  end
end
