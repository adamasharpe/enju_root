require 'test_helper'

class CheckedItemsControllerTest < ActionController::TestCase
  fixtures :checked_items, :baskets, :items, :manifestations, :exemplifies,
    :expressions, :works, :realizes, :embodies, :carrier_types,
    :item_has_use_restrictions, :use_restrictions,
    :checkout_types, :user_group_has_checkout_types,
    :checkouts, :reserves, :circulation_statuses, :carrier_type_has_checkout_types,
    :users, :roles, :patrons, :patron_types, :user_groups, :lending_policies

  def test_guest_should_not_get_index
    get :index, :basket_id => 1, :item_id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_everyone_should_not_get_index_without_basket_id
    sign_in users(:admin)
    get :index, :item_id => 1
    assert_response :forbidden
  end

  def test_everyone_should_not_get_index_without_item_id
    sign_in users(:admin)
    get :index, :item_id => 1
    assert_response :forbidden
  end

  def test_user_should_not_get_index
    sign_in users(:user1)
    get :index, :basket_id => 3, :item_id => 3
    assert_response :forbidden
  end

  def test_librarian_should_get_index
    sign_in users(:librarian1)
    get :index, :basket_id => 3, :item_id => 3
    assert_response :success
    assert assigns(:checked_items)
  end

  def test_librarian_should_get_index_with_list
    sign_in users(:librarian1)
    get :index, :basket_id => 3, :item_id => 3, :mode => 'list'
    assert_response :success
    assert assigns(:checked_items)
  end

  def test_guest_should_not_get_new
    get :new, :basket_id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end
  
  def test_everyone_should_not_get_new_without_basket_id
    sign_in users(:admin)
    get :new
    assert_response :forbidden
  end

  def test_user_should_not_get_new
    sign_in users(:user1)
    get :new, :basket_id => 3
    assert_response :forbidden
  end

  def test_librarian_should_get_new
    sign_in users(:librarian1)
    get :new, :basket_id => 3
    assert_response :success
  end

  def test_guest_should_not_create_checked_item
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => '00004'}, :basket_id => 1
    assert_equal old_count, CheckedItem.count
    
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_everyone_should_not_create_checked_item_without_item_id
    sign_in users(:admin)
    old_count = CheckedItem.count
    post :create, :checked_item => { }, :basket_id => 1
    assert_equal old_count, CheckedItem.count
    
    assert_response :success
    #assert_redirected_to user_basket_checked_items_url(assigns(:basket).user.username, assigns(:basket))
  end

  def test_everyone_should_not_create_checked_item_with_missing_item
    sign_in users(:admin)
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => 'not found'}, :basket_id => 1
    assert_equal old_count, CheckedItem.count
    
    assert_response :success
    #assert_redirected_to user_basket_checked_items_url(assigns(:basket).user.username, assigns(:basket))
    assert_equal 'Item not found.', assigns(:checked_item).errors["base"]
  end

  def test_everyone_should_not_create_checked_item_with_item_not_for_checkout
    sign_in users(:admin)
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => '00017'}, :basket_id => 1
    assert_equal old_count, CheckedItem.count
    
    assert_response :success
    #assert_redirected_to user_basket_checked_items_url(assigns(:basket).user.username, assigns(:basket))
    #assert flash[:message].include?('This item is not available for checkout.')
    assert assigns(:checked_item).errors["base"].include?('This item is not available for checkout.')
  end

  def test_everyone_should_not_create_checked_item_already_checked_out
    sign_in users(:admin)
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => '00013'}, :basket_id => 8
    assert_equal old_count, CheckedItem.count
    
    assert_response :success
    assert assigns(:checked_item).errors["base"].include?('This item is already checked out.')
  end

  def test_everyone_should_not_create_checked_item_in_transaction
    sign_in users(:admin)
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => '00006'}, :basket_id => 9
    assert_equal old_count, CheckedItem.count
    
    assert_response :success
    assert assigns(:checked_item).errors["base"].include?('In transaction.')
  end

  def test_everyone_should_not_create_checked_item_without_basket_id
    sign_in users(:admin)
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => '00004'}
    assert_equal old_count, CheckedItem.count
    
    assert_response :forbidden
  end

  def test_user_should_not_create_checked_item
    sign_in users(:user1)
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => '00004'}, :basket_id => 3
    assert_equal old_count, CheckedItem.count
    
    assert_response :forbidden
  end

  def test_librarian_should_create_checked_item
    sign_in users(:librarian1)
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => '00011'}, :basket_id => 3
    assert_equal old_count+1, CheckedItem.count
    assert_not_nil assigns(:checked_item).due_date
    
    assert_redirected_to user_basket_checked_items_url(assigns(:checked_item).basket.user.username, assigns(:checked_item).basket)
  end
  
  def test_librarian_should_create_checked_item_with_list
    sign_in users(:librarian1)
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => '00011'}, :basket_id => 3, :mode => 'list'
    assert_equal old_count+1, CheckedItem.count
    assert_not_nil assigns(:checked_item).due_date
    
    assert_redirected_to user_basket_checked_items_url(assigns(:checked_item).basket.user.username, assigns(:checked_item).basket, :mode => 'list')
  end
  
  def test_system_should_show_message_when_item_includes_supplements
    sign_in users(:librarian1)
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => '00006'}, :basket_id => 3
    assert_equal old_count+1, CheckedItem.count
    assert_not_nil assigns(:checked_item).due_date
    
    assert_redirected_to user_basket_checked_items_url(assigns(:checked_item).basket.user.username, assigns(:checked_item).basket)
    assert flash[:message].index('This item includes supplements.')
    #assert_nil assigns(:checked_item).errors
  end
  
  def test_librarian_should_not_create_checked_item_when_over_checkout_limit
    sign_in users(:librarian1)
    post :create, :checked_item => {:item_identifier => '00011'}, :basket_id => 1
    
    assert_response :success
    #assert_redirected_to user_basket_checked_items_path(assigns(:basket).user.username, assigns(:basket))
    assert assigns(:checked_item).errors["base"].include?('Excessed checkout limit.')
  end

  def test_librarian_should_create_checked_item_when_ignore_restriction_is_enabled
    sign_in users(:librarian1)
    old_count = CheckedItem.count
    post :create, :checked_item => {:item_identifier => '00011', :ignore_restriction => "1"}, :basket_id => 2, :mode => 'list'
    assert_equal old_count+1, CheckedItem.count
    assert_not_nil assigns(:checked_item).due_date
    
    assert_redirected_to user_basket_checked_items_url(assigns(:checked_item).basket.user.username, assigns(:checked_item).basket, :mode => 'list')
  end

  def test_guest_should_not_show_checked_item
    get :show, :id => 1, :basket_id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_guest_should_not_show_checked_item_without_basket_id
    sign_in users(:admin)
    get :show, :id => 1
    assert_response :forbidden
  end

  def test_user_should_not_show_checked_item
    sign_in users(:user1)
    get :show, :id => 3, :basket_id => 3
    assert_response :forbidden
  end

  def test_librarian_should_show_checked_item
    sign_in users(:librarian1)
    get :show, :id => 1, :basket_id => 1
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => 1, :basket_id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end
  
  def test_everyone_should_not_get_edit_without_basket_id
    sign_in users(:admin)
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_user_should_not_get_edit
    sign_in users(:user1)
    get :edit, :id => 3, :basket_id => 3
    assert_response :forbidden
  end
  
  def test_librarian_should_get_edit
    sign_in users(:librarian1)
    get :edit, :id => 1, :basket_id => 1
    assert_response :success
  end
  
  def test_guest_should_not_update_checked_item
    put :update, :id => 1, :checked_item => { }, :basket_id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_everyone_should_not_update_checked_item_without_basket_id
    sign_in users(:admin)
    put :update, :id => 1, :checked_item => { }
    assert_response :forbidden
  end

  def test_user_should_not_update_checked_item
    sign_in users(:user1)
    put :update, :id => 1, :checked_item => { }, :basket_id => 3
    assert_response :forbidden
  end

  def test_librarian_should_not_update_checked_item_without_basket_id
    sign_in users(:librarian1)
    put :update, :id => 1, :checked_item => {}
    assert_response :forbidden
  end

  def test_librarian_should_update_checked_item
    sign_in users(:librarian1)
    put :update, :id => 4, :checked_item => { }, :basket_id => 8
    assert_redirected_to checked_item_url(assigns(:checked_item))
    #assert_nil assigns(:checked_item).errors
  end

  def test_guest_should_not_destroy_checked_item
    old_count = CheckedItem.count
    delete :destroy, :id => 1, :basket_id => 1
    assert_equal old_count, CheckedItem.count
    
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_everyone_should_not_destroy_checked_item_without_basket_id
    sign_in users(:admin)
    old_count = CheckedItem.count
    delete :destroy, :id => 1
    assert_equal old_count, CheckedItem.count
    
    assert_response :forbidden
  end
  
  def test_user_should_not_destroy_checked_item
    sign_in users(:user1)
    old_count = CheckedItem.count
    delete :destroy, :id => 3, :basket_id => 3
    assert_equal old_count, CheckedItem.count
    
    assert_response :forbidden
  end
  
  def test_librarian_should_destroy_checked_item
    sign_in users(:librarian1)
    old_count = CheckedItem.count
    delete :destroy, :id => 1, :basket_id => 1
    assert_equal old_count-1, CheckedItem.count
    
    assert_redirected_to user_basket_checked_items_url(assigns(:checked_item).basket.user.username, assigns(:checked_item).basket)
  end

end
