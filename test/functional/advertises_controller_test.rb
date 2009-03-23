require 'test_helper'

class AdvertisesControllerTest < ActionController::TestCase
  fixtures :advertises, :advertisements, :users, :patrons

  def test_guest_should_not_get_index
    get :index
    assert_response :redirect
    assert_redirected_to new_user_session_url
    assert_nil assigns(:advertises)
  end

  def test_user_should_not_get_index
    set_session_for users(:user1)
    get :index
    assert_response :forbidden
    assert_nil assigns(:advertises)
  end

  def test_librarian_should_get_index
    set_session_for users(:librarian1)
    get :index
    assert_response :success
  end

  def test_admin_should_get_index
    set_session_for users(:admin)
    get :index
    assert_response :success
    assert assigns(:advertises)
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
  
  def test_librarian_should_not_get_new
    set_session_for users(:librarian1)
    get :new
    assert_response :forbidden
  end
  
  def test_admin_should_get_new
    set_session_for users(:admin)
    get :new
    assert_response :success
  end
  
  def test_guest_should_not_create_advertise
    old_count = Advertise.count
    post :create, :advertise => { }
    assert_equal old_count, Advertise.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_advertise
    set_session_for users(:user1)
    old_count = Advertise.count
    post :create, :advertise => { }
    assert_equal old_count, Advertise.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_create_advertise
    set_session_for users(:librarian1)
    old_count = Advertise.count
    post :create, :advertise => { }
    assert_equal old_count, Advertise.count
    
    assert_response :forbidden
  end

  def test_admin_should_not_create_advertise_already_created
    set_session_for users(:admin)
    old_count = Advertise.count
    post :create, :advertise => {:patron_id =>1, :advertisement_id => 1}
    assert_equal old_count, Advertise.count
    
    assert_response :success
  end

  def test_admin_should_create_advertise
    set_session_for users(:admin)
    old_count = Advertise.count
    post :create, :advertise => {:patron_id =>1, :advertisement_id => 3}
    assert_equal old_count+1, Advertise.count
    
    assert_redirected_to advertise_url(assigns(:advertise))
  end

  def test_guest_should_not_show_advertise
    get :show, :id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_show_advertise
    set_session_for users(:user1)
    get :show, :id => 1
    assert_response :forbidden
  end

  def test_librarian_should_show_advertise
    set_session_for users(:librarian1)
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_advertise
    set_session_for users(:admin)
    get :show, :id => 1
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => 1
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_edit
    set_session_for users(:user1)
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_librarian_should_not_get_edit
    set_session_for users(:librarian1)
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_admin_should_get_edit
    set_session_for users(:admin)
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_guest_should_not_update_advertise
    put :update, :id => 1, :advertise => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_update_advertise
    set_session_for users(:user1)
    put :update, :id => 1, :advertise => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_advertise
    set_session_for users(:librarian1)
    put :update, :id => 1, :advertise => { }
    assert_response :forbidden
  end
  
  def test_admin_should_update_advertise
    set_session_for users(:admin)
    put :update, :id => 1, :advertise => { }
    assert_redirected_to advertise_url(assigns(:advertise))
  end
  
  def test_guest_should_not_destroy_advertise
    old_count = Advertise.count
    delete :destroy, :id => 1
    assert_equal old_count, Advertise.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_advertise
    set_session_for users(:user1)
    old_count = Advertise.count
    delete :destroy, :id => 1
    assert_equal old_count, Advertise.count
    
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_advertise
    set_session_for users(:librarian1)
    old_count = Advertise.count
    delete :destroy, :id => 1
    assert_equal old_count, Advertise.count
    
    assert_response :forbidden
  end

  def test_admin_should_destroy_advertise
    set_session_for users(:admin)
    old_count = Advertise.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Advertise.count
    
    assert_redirected_to advertises_url
  end
end
