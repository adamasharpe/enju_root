require File.dirname(__FILE__) + '/../test_helper'
require 'events_controller'

class EventsControllerTest < ActionController::TestCase
  fixtures :events, :event_categories, :libraries
  fixtures :patrons, :users

  def test_guest_should_get_index
    get :index
    assert_response :success
    assert assigns(:events)
  end

  def test_guest_should_get_index_csv
    get :index, :format => 'csv'
    assert_response :success
    assert assigns(:events)
  end

  def test_guest_should_get_index_rss
    get :index, :format => 'rss'
    assert_response :success
    assert assigns(:events)
  end

  def test_guest_should_get_index_with_library_id
    get :index, :library_id => 'kamata'
    assert_response :success
    assert assigns(:library)
    assert assigns(:events)
  end

  def test_user_should_get_index
    login_as :user1
    get :index
    assert_response :success
    assert assigns(:events)
  end

  def test_librarian_should_get_index
    login_as :librarian1
    get :index
    assert_response :success
    assert assigns(:events)
  end

  def test_admin_should_get_index
    login_as :admin
    get :index
    assert_response :success
    assert assigns(:events)
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
    assert_response :success
  end
  
  def test_admin_should_get_new
    login_as :admin
    get :new
    assert_response :success
  end
  
  def test_guest_should_not_create_event
    old_count = Event.count
    post :create, :event => { :title => 'test', :library_id => '1', :event_category_id => 1, :started_at => '2008-02-05', :ended_at => '2008-02-08' }
    assert_equal old_count, Event.count
    
    assert_redirected_to new_session_url
  end

  def test_user_should_not_create_event
    old_count = Event.count
    post :create, :event => { :title => 'test', :library_id => '1', :event_category_id => 1, :started_at => '2008-02-05', :ended_at => '2008-02-08' }
    assert_equal old_count, Event.count
    
    assert_redirected_to new_session_url
  end

  def test_librarian_should_create_event_without_library_id
    login_as :librarian1
    old_count = Event.count
    post :create, :event => { :title => 'test', :event_category_id => 1, :started_at => '2008-02-05', :ended_at => '2008-02-08' }
    assert_equal old_count+1, Event.count
    
    assert_redirected_to event_url(assigns(:event))
  end

  def test_librarian_should_create_event_without_category_id
    login_as :librarian1
    old_count = Event.count
    post :create, :event => { :title => 'test', :library_id => '1', :started_at => '2008-02-05', :ended_at => '2008-02-08' }
    assert_equal old_count+1, Event.count
    
    assert_redirected_to event_url(assigns(:event))
  end

  def test_librarian_should_not_create_event_with_invalid_dates
    login_as :librarian1
    old_count = Event.count
    post :create, :event => { :title => 'test', :library_id => '1', :event_category_id => 1, :started_at => '2008-02-08', :ended_at => '2008-02-05' }
    assert_equal old_count, Event.count
    
    assert_response :success
    assert assigns(:event).errors.on(:started_at)
  end

  def test_librarian_should_create_event
    login_as :librarian1
    old_count = Event.count
    post :create, :event => { :title => 'test', :library_id => '1', :event_category_id => 1, :started_at => '2008-02-05', :ended_at => '2008-02-08' }
    assert_equal old_count+1, Event.count
    
    assert_redirected_to event_url(assigns(:event))
  end

  def test_admin_should_create_event
    login_as :admin
    old_count = Event.count
    post :create, :event => { :title => 'test', :library_id => '1', :event_category_id => 1, :started_at => '2008-02-05', :ended_at => '2008-02-08' }
    assert_equal old_count+1, Event.count
    
    assert_redirected_to event_url(assigns(:event))
  end

  def test_guest_should_show_event
    get :show, :id => 1
    assert_response :success
  end

  def test_user_should_show_event
    login_as :user1
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_event
    login_as :librarian1
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_event
    login_as :admin
    get :show, :id => 1
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => 1
    assert_response :redirect
    assert_redirected_to new_session_url
  end
  
  def test_user_should_not_get_edit
    login_as :user1
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_librarian_should_get_edit
    login_as :librarian1
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_admin_should_get_edit
    login_as :admin
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_guest_should_not_update_event
    put :update, :id => 1, :event => { }
    assert_redirected_to new_session_url
  end
  
  def test_user_should_not_update_event
    login_as :user1
    put :update, :id => 1, :event => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_update_event_without_library_id
    login_as :librarian1
    put :update, :id => 1, :event => {:library_id => nil}
    assert_response :success
  end
  
  def test_librarian_should_update_event_without_event_category_id
    login_as :librarian1
    put :update, :id => 1, :event => {:event_category_id => nil}
    assert_response :success
  end
  
  def test_librarian_should_not_update_event_with_invalid_date
    login_as :librarian1
    put :update, :id => 1, :event => {:started_at => '2008-02-08', :ended_at => '2008-02-05' }
    assert_response :success
    assert assigns(:event).errors.on(:started_at)
  end
  
  def test_librarian_should_update_event
    login_as :librarian1
    put :update, :id => 1, :event => { }
    assert_redirected_to event_url(assigns(:event))
  end
  
  def test_admin_should_update_event
    login_as :admin
    put :update, :id => 1, :event => { }
    assert_redirected_to event_url(assigns(:event))
  end
  
  def test_guest_should_not_destroy_event
    old_count = Event.count
    delete :destroy, :id => 1
    assert_equal old_count, Event.count
    
    assert_redirected_to new_session_url
  end

  def test_user_should_not_destroy_event
    login_as :user1
    old_count = Event.count
    delete :destroy, :id => 1
    assert_equal old_count, Event.count
    
    assert_response :forbidden
  end

  def test_librarian_should_destroy_event
    login_as :librarian1
    old_count = Event.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Event.count
    
    assert_redirected_to events_url
  end

  def test_admin_should_destroy_event
    login_as :admin
    old_count = Event.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Event.count
    
    assert_redirected_to events_url
  end
end
