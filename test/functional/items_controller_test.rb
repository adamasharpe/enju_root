require File.dirname(__FILE__) + '/../test_helper'
require 'items_controller'

class ItemsControllerTest < ActionController::TestCase
  fixtures :items, :circulation_statuses, :shelves, :orders, :manifestations, :exemplifies, :manifestation_forms, :languages, :reserves
  fixtures :libraries, :patrons, :users, :inventories, :inventory_files
  fixtures :people, :corporate_bodies, :families

  def test_guest_should_get_index
    get :index
    assert_response :success
    assert assigns(:items)
  end

  def test_guest_should_get_index_with_patron_id
    get :index, :patron_id => 1
    assert_response :success
    assert assigns(:patron)
    assert assigns(:items)
  end

  def test_guest_should_get_index_with_manifestation_id
    get :index, :manifestation_id => 1
    assert_response :success
    assert assigns(:manifestation)
    assert assigns(:items)
  end

  def test_guest_should_get_index_with_shelf_id
    get :index, :shelf_id => 1
    assert_response :success
    assert assigns(:shelf)
    assert assigns(:items)
  end

  def test_guest_not_should_get_index_with_inventory_file_id
    get :index, :inventory_file_id => 1
    assert_response :redirect
    assert_redirected_to new_session_url
    assert assigns(:inventory_file)
    assert_nil assigns(:items)
  end

  def test_user_should_get_index
    login_as :user1
    get :index
    assert_response :success
    assert assigns(:items)
  end

  def test_user_not_should_get_index_with_inventory_file_id
    login_as :user1
    get :index, :inventory_file_id => 1
    assert_response :forbidden
  end

  def test_librarian_should_get_index
    login_as :librarian1
    get :index
    assert_response :success
    assert assigns(:items)
  end

  def test_librarian_should_get_index_with_inventory_file_id
    login_as :librarian1
    get :index, :inventory_file_id => 1
    assert_response :success
    assert assigns(:inventory_file)
    assert assigns(:items)
  end

  def test_admin_should_get_index
    login_as :admin
    get :index
    assert_response :success
    assert assigns(:items)
  end

  def test_guest_should_not_get_new
    get :new
    assert_redirected_to new_session_url
  end
  
  def test_everyone_should_not_get_new_without_manifestation_id
    login_as :admin
    get :new
    assert_redirected_to manifestations_url
  end
  
  def test_user_should_not_get_new
    login_as :user1
    get :new, :manifestation_id => 1
    assert_response :forbidden
  end
  
  def test_librarian_should_get_new
    login_as :librarian1
    get :new, :manifestation_id => 1
    assert_response :success
  end
  
  def test_admin_should_get_new
    login_as :admin
    get :new, :manifestation_id => 1
    assert_response :success
  end
  
  def test_guest_should_not_create_item
    old_count = Item.count
    post :create, :item => { :circulation_status_id => 1, :manifestation_id => 1 }
    assert_equal old_count, Item.count
    
    assert_redirected_to new_session_url
  end

  def test_everyone_should_not_create_item_without_manifestation_id
    login_as :admin
    old_count = Item.count
    post :create, :item => { :circulation_status_id => 1 }
    assert_equal old_count, Item.count
    
    assert_response :redirect
    assert_redirected_to manifestations_url
  end

  def test_everyone_should_not_create_item_already_created
    login_as :admin
    old_count = Item.count
    post :create, :item => { :circulation_status_id => 1, :item_identifier => "00001" }, :manifestation_id => 1
    assert_equal old_count, Item.count
    
    assert_response :success
  end

  def test_user_should_not_create_item
    login_as :user1
    old_count = Item.count
    post :create, :item => { :circulation_status_id => 1 }, :manifestation_id => 1
    assert_equal old_count, Item.count
    
    assert_response :forbidden
  end

  def test_librarian_should_create_item
    login_as :librarian1
    old_count = Item.count
    post :create, :item => { :circulation_status_id => 1 }, :manifestation_id => 1
    assert_equal old_count+1, Item.count
    
    assert_redirected_to item_url(assigns(:item))
  end

  def test_admin_should_create_item
    login_as :admin
    old_count = Item.count
    post :create, :item => { :circulation_status_id => 1 }, :manifestation_id => 1
    assert_equal old_count+1, Item.count
    
    assert_redirected_to item_url(assigns(:item))
  end

  def test_guest_should_show_item
    get :show, :id => 1
    assert_response :success
  end

  def test_everyone_should_not_show_missing_item
    login_as :admin
    get :show, :id => 100
    assert_response :missing
  end

  def test_user_should_show_item
    login_as :user1
    get :show, :id => 1
    assert_response :success
  end

  def test_librarian_should_show_item
    login_as :librarian1
    get :show, :id => 1
    assert_response :success
  end

  def test_admin_should_show_item
    login_as :admin
    get :show, :id => 1
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => 1
    assert_response :redirect
    assert_redirected_to new_session_url
  end
  
  def test_everyone_should_not_edit_missing_item
    login_as :admin
    get :edit, :id => 100
    assert_response :missing
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
  
  def test_guest_should_not_update_item
    put :update, :id => 1, :item => { }
    assert_redirected_to new_session_url
  end
  
  def test_everyone_should_not_update_missing_item
    login_as :admin
    put :update, :id => 100, :item => { }
    assert_response :missing
  end
  
  def test_user_should_not_update_item
    login_as :user1
    put :update, :id => 1, :item => { }
    assert_response :forbidden
  end
  
  def test_librarian_should_not_update_item_without_circulation_status_id
    login_as :librarian1
    put :update, :id => 1, :item => {:circulation_status_id => nil}
    assert_response :success
  end
  
  def test_librarian_should_update_item
    login_as :librarian1
    put :update, :id => 1, :item => { :circulation_status_id => 1 }, :manifestation_id => 1
    assert_redirected_to item_url(assigns(:item))
  end
  
  def test_admin_should_update_item
    login_as :admin
    put :update, :id => 1, :item => { :circulation_status_id => 1 }, :manifestation_id => 1
    assert_redirected_to item_url(assigns(:item))
  end
  
  def test_guest_should_not_destroy_item
    old_count = Item.count
    delete :destroy, :id => 1
    assert_equal old_count, Item.count
    
    assert_redirected_to new_session_url
  end

  def test_everyone_should_not_destroy_missing_item
    login_as :admin
    old_count = Item.count
    delete :destroy, :id => 100
    assert_equal old_count, Item.count
    
    assert_response :missing
  end

  def test_user_should_not_destroy_item
    login_as :user1
    old_count = Item.count
    delete :destroy, :id => 1
    assert_equal old_count, Item.count
    
    assert_response :forbidden
  end

  def test_librarian_should_destroy_item
    login_as :librarian1
    old_count = Item.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Item.count
    
    assert_redirected_to items_url
  end

  def test_admin_should_destroy_item
    login_as :admin
    old_count = Item.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Item.count
    
    assert_redirected_to items_url
  end
end
