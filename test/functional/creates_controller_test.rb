require 'test_helper'

class CreatesControllerTest < ActionController::TestCase
  setup :activate_authlogic
  fixtures :creates, :works, :patrons, :users, :work_forms, :languages

  def test_guest_should_get_index
    get :index
    assert_response :success
    assert assigns(:creates)
  end

  def test_guest_should_get_index_with_patron_id
    get :index, :patron_id => 1
    assert_response :success
    assert assigns(:creates)
  end

  def test_guest_should_get_index_with_work_id
    get :index, :work_id => 1
    assert_response :success
    assert assigns(:creates)
  end

  def test_user_should_get_index
    UserSession.create users(:user1)
    get :index
    assert_response :success
    assert assigns(:creates)
  end

  def test_librarian_should_get_index
    UserSession.create users(:librarian1)
    get :index
    assert_response :success
    assert assigns(:creates)
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
  
  def test_guest_should_not_create_create
    old_count = Create.count
    post :create, :create => { :patron_id => 1, :work_id => 1 }
    assert_equal old_count, Create.count
    
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_create
    UserSession.create users(:user1)
    old_count = Create.count
    post :create, :create => { :patron_id => 1, :work_id => 1 }
    assert_equal old_count, Create.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_create_without_patron_id
    UserSession.create users(:librarian1)
    old_count = Create.count
    post :create, :create => { :work_id => 1 }
    assert_equal old_count, Create.count
    
    assert_response :success
  end

  def test_librarian_should_not_create_create_without_work_id
    UserSession.create users(:librarian1)
    old_count = Create.count
    post :create, :create => { :patron_id => 1 }
    assert_equal old_count, Create.count
    
    assert_response :success
  end

  def test_librarian_should_not_create_create_already_created
    UserSession.create users(:librarian1)
    old_count = Create.count
    post :create, :create => { :patron_id => 1, :work_id => 1 }
    assert_equal old_count, Create.count
    
    assert_response :success
  end

  def test_librarian_should_create_create_not_created_yet
    UserSession.create users(:librarian1)
    old_count = Create.count
    post :create, :create => { :patron_id => 1, :work_id => 3 }
    assert_equal old_count+1, Create.count
    
    assert_redirected_to create_url(assigns(:create))
  end

  def test_guest_should_show_create
    get :show, :id => 1
    assert_response :success
  end

  def test_user_should_show_create
    UserSession.create users(:user1)
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_create
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
    get :edit, :id => 1, :patron_id => 1
    assert_response :forbidden
  end
  
  def test_librarian_should_get_edit
    UserSession.create users(:librarian1)
    get :edit, :id => 1, :patron_id => 1
    assert_response :success
  end
  
  def test_guest_should_not_update_create
    put :update, :id => 1, :create => { }
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_create
    UserSession.create users(:user1)
    put :update, :id => 1, :create => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_create_without_patron_id
    UserSession.create users(:librarian1)
    put :update, :id => 1, :create => {:patron_id => nil}
    assert_response :success
  end
  
  def test_librarian_should_not_update_create_without_work_id
    UserSession.create users(:librarian1)
    put :update, :id => 1, :create => {:work_id => nil}
    assert_response :success
  end
  
  def test_librarian_should_update_create
    UserSession.create users(:librarian1)
    put :update, :id => 1, :create => { }
    assert_redirected_to create_url(assigns(:create))
  end
  
  def test_guest_should_not_destroy_create
    old_count = Create.count
    delete :destroy, :id => 1
    assert_equal old_count, Create.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_create
    UserSession.create users(:user1)
    old_count = Create.count
    delete :destroy, :id => 1
    assert_equal old_count, Create.count
    
    assert_response :forbidden
  end

  def test_librarian_should_destroy_create
    UserSession.create users(:librarian1)
    old_count = Create.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Create.count
    
    assert_redirected_to creates_url
  end
end
