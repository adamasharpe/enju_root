require 'test_helper'

class FrequencyOfIssuesControllerTest < ActionController::TestCase
  fixtures :frequency_of_issues, :users

  def test_guest_should_get_index
    get :index
    assert_response :success
  end

  def test_user_should_not_get_index
    login_as :user1
    get :index
    assert_response :success
    assert assigns(:frequency_of_issues)
  end

  def test_librarian_should_not_get_index
    login_as :librarian1
    get :index
    assert_response :success
    assert assigns(:frequency_of_issues)
  end

  def test_admin_should_get_index
    login_as :admin
    get :index
    assert_response :success
    assert assigns(:frequency_of_issues)
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
  
  def test_guest_should_not_create_frequency_of_issue
    old_count = FrequencyOfIssue.count
    post :create, :frequency_of_issue => { }
    assert_equal old_count, FrequencyOfIssue.count
    
    assert_redirected_to new_session_url
  end

  def test_user_should_not_create_frequency_of_issue
    login_as :user1
    old_count = FrequencyOfIssue.count
    post :create, :frequency_of_issue => { }
    assert_equal old_count, FrequencyOfIssue.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_frequency_of_issue
    login_as :librarian1
    old_count = FrequencyOfIssue.count
    post :create, :frequency_of_issue => { }
    assert_equal old_count, FrequencyOfIssue.count
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_frequency_of_issue_without_name
    login_as :admin
    old_count = FrequencyOfIssue.count
    post :create, :frequency_of_issue => { }
    assert_equal old_count, FrequencyOfIssue.count
    
    assert_response :success
  end

  def test_admin_should_create_frequency_of_issue
    login_as :admin
    old_count = FrequencyOfIssue.count
    post :create, :frequency_of_issue => {:name => 'test'}
    assert_equal old_count+1, FrequencyOfIssue.count
    
    assert_redirected_to frequency_of_issue_url(assigns(:frequency_of_issue))
  end

  def test_guest_should_show_frequency_of_issue
    get :show, :id => 1
    assert_response :success
  end

  def test_user_should_show_frequency_of_issue
    login_as :user1
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_frequency_of_issue
    login_as :librarian1
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_frequency_of_issue
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
  
  def test_guest_should_not_update_frequency_of_issue
    put :update, :id => 1, :frequency_of_issue => { }
    assert_redirected_to new_session_url
  end
  
  def test_user_should_not_update_frequency_of_issue
    login_as :user1
    put :update, :id => 1, :frequency_of_issue => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_frequency_of_issue
    login_as :librarian1
    put :update, :id => 1, :frequency_of_issue => { }
    assert_response :forbidden
  end
  
  def test_admin_should_not_update_frequency_of_issue_without_name
    login_as :admin
    put :update, :id => 1, :frequency_of_issue => {:name => nil}
    assert_response :success
  end
  
  def test_admin_should_update_frequency_of_issue
    login_as :admin
    put :update, :id => 1, :frequency_of_issue => { }
    assert_redirected_to frequency_of_issue_url(assigns(:frequency_of_issue))
  end
  
  def test_guest_should_not_destroy_frequency_of_issue
    old_count = FrequencyOfIssue.count
    delete :destroy, :id => 1
    assert_equal old_count, FrequencyOfIssue.count
    
    assert_redirected_to new_session_url
  end

  def test_user_should_not_destroy_frequency_of_issue
    login_as :user1
    old_count = FrequencyOfIssue.count
    delete :destroy, :id => 1
    assert_equal old_count, FrequencyOfIssue.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_frequency_of_issue
    login_as :librarian1
    old_count = FrequencyOfIssue.count
    delete :destroy, :id => 1
    assert_equal old_count, FrequencyOfIssue.count
    
    assert_response :forbidden
  end

  def test_admin_should_destroy_frequency_of_issue
    login_as :admin
    old_count = FrequencyOfIssue.count
    delete :destroy, :id => 1
    assert_equal old_count-1, FrequencyOfIssue.count
    
    assert_redirected_to frequency_of_issues_url
  end
end
