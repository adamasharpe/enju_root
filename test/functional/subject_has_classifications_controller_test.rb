require 'test_helper'

class SubjectHasClassificationsControllerTest < ActionController::TestCase
  setup :activate_authlogic
  fixtures :subject_has_classifications, :classifications, :users, :subjects

  def test_guest_should_get_index
    get :index
    assert_response :success
    assert assigns(:subject_has_classifications)
  end

  def test_guest_should_get_index_with_subject_id
    get :index, :subject_id => 1
    assert_response :success
    assert assigns(:subject_has_classifications)
  end

  def test_guest_should_get_index_with_classification_id
    get :index, :classification_id => 1
    assert_response :success
    assert assigns(:subject_has_classifications)
  end

  def test_user_should_get_index
    UserSession.create users(:user1)
    get :index
    assert_response :success
    assert assigns(:subject_has_classifications)
  end

  def test_librarian_should_get_index
    UserSession.create users(:librarian1)
    get :index
    assert_response :success
    assert assigns(:subject_has_classifications)
  end

  def test_guest_should_not_get_new
    get :new
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_new
    UserSession.create users(:user1)
    get :new
    assert_response :forbidden
  end
  
  def test_librarian_should_get_new
    UserSession.create users(:librarian1)
    get :new
    assert_response :success
  end
  
  def test_guest_should_not_create_subject_has_classification
    old_count = SubjectHasClassification.count
    post :create, :subject_has_classification => { :subject_id => 1, :classification_id => 1 }
    assert_equal old_count, SubjectHasClassification.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_subject_has_classification
    old_count = SubjectHasClassification.count
    post :create, :subject_has_classification => { :subject_id => 1, :classification_id => 1 }
    assert_equal old_count, SubjectHasClassification.count
    
    assert_redirected_to new_user_session_url
  end

  def test_librarian_should_not_create_subject_has_classification_without_subject_id
    UserSession.create users(:librarian1)
    old_count = SubjectHasClassification.count
    post :create, :subject_has_classification => { :classification_id => 1 }
    assert_equal old_count, SubjectHasClassification.count
    
    assert_response :success
  end

  def test_librarian_should_not_create_subject_has_classification_without_classification_id
    UserSession.create users(:librarian1)
    old_count = SubjectHasClassification.count
    post :create, :subject_has_classification => { :subject_id => 1 }
    assert_equal old_count, SubjectHasClassification.count
    
    assert_response :success
  end

  def test_librarian_should_not_create_subject_has_classification_already_created
    UserSession.create users(:librarian1)
    old_count = SubjectHasClassification.count
    post :create, :subject_has_classification => { :subject_id => 1, :classification_id => 1 }
    assert_equal old_count, SubjectHasClassification.count
    
    assert_response :success
  end

  def test_librarian_should_create_subject_has_classification_not_created_yet
    UserSession.create users(:librarian1)
    old_count = SubjectHasClassification.count
    post :create, :subject_has_classification => { :subject_id => 1, :classification_id => 3 }
    assert_equal old_count+1, SubjectHasClassification.count
    
    assert_redirected_to subject_has_classification_path(assigns(:subject_has_classification))
  end

  def test_guest_should_show_subject_has_classification
    get :show, :id => 1
    assert_response :success
  end

  def test_user_should_show_subject_has_classification
    UserSession.create users(:user1)
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_subject_has_classification
    UserSession.create users(:librarian1)
    get :show, :id => 1
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_edit
    UserSession.create users(:user1)
    get :edit, :id => 1, :subject_id => 1
    assert_response :forbidden
  end
  
  def test_librarian_should_get_edit
    UserSession.create users(:librarian1)
    get :edit, :id => 1, :subject_id => 1
    assert_response :success
  end
  
  def test_guest_should_not_update_subject_has_classification
    put :update, :id => 1, :subject_has_classification => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_subject_has_classification
    UserSession.create users(:user1)
    put :update, :id => 1, :subject_has_classification => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_subject_has_classification_without_subject_id
    UserSession.create users(:librarian1)
    put :update, :id => 1, :subject_has_classification => {:subject_id => nil}
    assert_response :success
  end
  
  def test_librarian_should_not_update_subject_has_classification_without_classification_id
    UserSession.create users(:librarian1)
    put :update, :id => 1, :subject_has_classification => {:classification_id => nil}
    assert_response :success
  end
  
  def test_librarian_should_update_subject_has_classification
    UserSession.create users(:librarian1)
    put :update, :id => 1, :subject_has_classification => { }
    assert_redirected_to subject_has_classification_url(assigns(:subject_has_classification))
  end
  
  def test_guest_should_not_destroy_subject_has_classification
    old_count = SubjectHasClassification.count
    delete :destroy, :id => 1
    assert_equal old_count, SubjectHasClassification.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_subject_has_classification
    UserSession.create users(:user1)
    old_count = SubjectHasClassification.count
    delete :destroy, :id => 1
    assert_equal old_count, SubjectHasClassification.count
    
    assert_response :forbidden
  end

  def test_librarian_should_destroy_subject_has_classification
    UserSession.create users(:librarian1)
    old_count = SubjectHasClassification.count
    delete :destroy, :id => 1
    assert_equal old_count-1, SubjectHasClassification.count
    
    assert_redirected_to subject_has_classifications_url
  end

  def test_librarian_should_destroy_subject_has_classification_with_subject_id
    UserSession.create users(:librarian1)
    old_count = SubjectHasClassification.count
    delete :destroy, :id => 1, :subject_id => 1
    assert_equal old_count-1, SubjectHasClassification.count
    
    assert_redirected_to subject_subject_has_classifications_url(subjects(:subject_00001))
  end

  def test_librarian_should_destroy_subject_has_classification_with_classification_id
    UserSession.create users(:librarian1)
    old_count = SubjectHasClassification.count
    delete :destroy, :id => 1, :classification_id => 1
    assert_equal old_count-1, SubjectHasClassification.count
    
    assert_redirected_to classification_subject_has_classifications_url(classifications(:classification_00001))
  end
end
