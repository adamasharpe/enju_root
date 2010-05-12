require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.

  fixtures :users, :roles, :patrons, :libraries, :checkouts, :checkins, :patron_types, :advertisements, :tags, :taggings,
    :manifestations, :carrier_types, :expressions, :embodies, :works, :realizes, :creates, :reifies, :produces

  def test_guest_should_not_get_index
    assert_raise(CanCan::AccessDenied){
      get :index
    }
    #assert_response :redirect
    #assert_redirected_to new_user_session_url
  end

  def test_user_should_not_get_index
    sign_in users(:user1)
    assert_raise(CanCan::AccessDenied){
      get :index
    }
    #assert_response :forbidden
  end

  def test_librarian_should_get_index
    sign_in users(:librarian1)
    get :index
    assert_response :success
    assert assigns(:users)
  end

  def test_guest_should_not_update_user
    assert_raise(CanCan::AccessDenied){
      put :update, :id => 'admin', :user => { }
    }
    #assert_response :redirect
    #assert_redirected_to new_user_session_url
  end

  def test_user_should_update_myself
    sign_in users(:user1)
    put :update, :id => users(:user1).username, :user => { }
    assert_redirected_to user_url(assigns(:user).username)
    assigns(:user).remove_from_index!
  end

  #def test_user_should_not_update_myself_without_login
  #  sign_in users(:user1)
  #  put :update, :id => users(:user1).username, :user => {:username => ""}
  #  assert_redirected_to user_url(assigns(:user).username)
  #  assert_equal assigns(:user).username, users(:user1).username
  #end

  def test_user_should_not_update_my_role
    sign_in users(:user1)
    put :update, :id => users(:user1).username, :user => {:role_id => 4}
    assert_redirected_to user_url(assigns(:user).username)
    assert !assigns(:user).roles.include?(Role.find_by_name('Administrator'))
  end

  def test_user_should_not_update_my_user_group
    sign_in users(:user1)
    put :update, :id => users(:user1).username, :user => {:user_group_id => 3}
    assert_redirected_to user_url(assigns(:user).username)
    assert_equal assigns(:user).user_group.id, 1
  end

  def test_user_should_not_update_my_note
    sign_in users(:user1)
    put :update, :id => users(:user1).username, :user => {:note => 'test'}
    assert_redirected_to user_url(assigns(:user).username)
    assert_nil assigns(:user).note
  end

  def test_user_should_update_my_keyword_list
    sign_in users(:user1)
    put :update, :id => users(:user1).username, :user => {:keyword_list => 'test'}
    assert_redirected_to user_url(assigns(:user).username)
    assert_equal assigns(:user).keyword_list, 'test'
    assigns(:user).remove_from_index!
  end

  def test_user_should_not_update_other_user
    sign_in users(:user1)
    assert_raise(CanCan::AccessDenied){
      put :update, :id => users(:user2).username, :user => { }
    }
    #assert_response :forbidden
  end

  def test_librarian_should_update_other_user
    sign_in users(:librarian1)
    put :update, :id => users(:user1).username, :user => {:user_number => '00003', :locale => 'en'}
    assert_redirected_to user_url(assigns(:user).username)
    assigns(:user).remove_from_index!
  end

  def test_librarian_should_not_update_other_role
    sign_in users(:librarian1)
    put :update, :id => users(:user1).username, :user => {:role_id => 4, :locale => 'en'}
    assert_redirected_to user_url(assigns(:user).username)
    assert !assigns(:user).roles.include?(Role.find_by_name('Administrator'))
  end

  def test_admin_should_update_other_role
    sign_in users(:admin)
    put :update, :id => users(:user1).username, :user => {:role_id => 4, :locale => 'en'}
    assert_redirected_to user_url(assigns(:user).username)
    assert assigns(:user).roles.include?(Role.find_by_name('Administrator'))
    assigns(:user).remove_from_index!
  end

  def test_librarian_should_update_other_user_group
    sign_in users(:librarian1)
    put :update, :id => users(:user1).username, :user => {:user_group_id => 3, :locale => 'en'}
    assert_redirected_to user_url(assigns(:user).username)
    assert_equal assigns(:user).user_group_id, 3
    assigns(:user).remove_from_index!
  end

  def test_librarian_should_update_other_note
    sign_in users(:librarian1)
    put :update, :id => users(:user1).username, :user => {:note => 'test', :locale => 'en'}
    assert_redirected_to user_url(assigns(:user).username)
    assert_equal assigns(:user).note, 'test'
    assigns(:user).remove_from_index!
  end

  def test_guest_should_get_new
    assert_raise(CanCan::AccessDenied){
      get :new, :patron_id => 6
    }
    assert_response :success
  end

  def test_librarian_should_get_new_without_patron_id
    sign_in users(:librarian1)
    get :new
    assert_response :success
  end

  def test_user_should_not_get_new
    sign_in users(:user1)
    assert_raise(CanCan::AccessDenied){
      get :new, :patron_id => 6
    }
    #assert_response :forbidden
  end

  def test_librarian_should_get_new
    sign_in users(:librarian1)
    get :new, :patron_id => 6
    assert_response :success
  end

  def test_guest_should_not_show_user
    assert_raise(CanCan::AccessDenied){
      get :show, :id => users(:user1).username
    }
    #assert_response :redirect
    #assert_redirected_to new_user_session_url
  end

  def test_user_should_show_my_user
    sign_in users(:user1)
    get :show, :id => users(:user1).username
    assert_response :success
  end

  def test_user_should_show_other_user
    sign_in users(:user1)
    get :show, :id => users(:admin).username
    assert_response :success
  end

  def test_everyone_should_not_show_missing_user
    sign_in users(:admin)
    assert_raise(ActiveRecord::RecordNotFound){
      get :show, :id => 100
    } 
    #assert_response :missing
  end

  def test_guest_should_not_edit_user
    assert_raise(CanCan::AccessDenied){
      get :edit, :id => 1
    }
    #assert_response :redirect
    #assert_redirected_to new_user_session_url
  end

  def test_everyone_should_not_edit_missing_user
    sign_in users(:admin)
    assert_raise(ActiveRecord::RecordNotFound){
      get :edit, :id => 100
    }
    #assert_response :missing
  end

  def test_user_should_edit_my_user
    sign_in users(:user1)
    get :edit, :id => users(:user1).username
    assert_response :success
  end

  def test_librarian_should_edit_other_user
    sign_in users(:librarian1)
    get :edit, :id => users(:user1).username
    assert_response :success
  end

  def test_guest_should_not_destroy_user
    old_count = User.count
    assert_raise(CanCan::AccessDenied){
      delete :destroy, :id => 1
    }
    assert_equal old_count, User.count
    #assert_response :redirect
    #assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_myself
    sign_in users(:user1)
    old_count = User.count
    assert_raise(CanCan::AccessDenied){
      delete :destroy, :id => users(:user1).username
    }
    assert_equal old_count, User.count
    #assert_response :forbidden
  end

  def test_user_should_not_destroy_other_user
    sign_in users(:user1)
    old_count = User.count
    assert_raise(CanCan::AccessDenied){
      delete :destroy, :id => users(:user2).username
    }
    assert_equal old_count, User.count
    #assert_response :forbidden
  end

  def test_librarian_should_not_destroy_myself
    sign_in users(:librarian1)
    old_count = User.count
    assert_raise(CanCan::AccessDenied){
      delete :destroy, :id => users(:librarian1).username
    }
    assert_equal old_count, User.count
    #assert_response :forbidden
  end

  def test_librarian_should_destroy_user
    sign_in users(:librarian1)
    old_count = User.count
    delete :destroy, :id => users(:user2).username
    assert_equal old_count-1, User.count
    assert_redirected_to users_url
  end

  def test_librarian_should_not_destroy_user_who_has_items_not_checked_in
    sign_in users(:librarian1)
    old_count = User.count
    assert_raise(CanCan::AccessDenied){
      delete :destroy, :id => users(:user1).username
    }
    assert_equal old_count, User.count
    #assert_response :forbidden
  end

  def test_librarian_should_not_destroy_librarian
    sign_in users(:librarian1)
    old_count = User.count
    assert_raise(CanCan::AccessDenied){
      delete :destroy, :id => users(:librarian2).username
    }
    assert_equal old_count, User.count
    #assert_response :forbidden
  end

  def test_librarian_should_not_destroy_admin
    sign_in users(:librarian1)
    old_count = User.count
    assert_raise(CanCan::AccessDenied){
      delete :destroy, :id => users(:admin).username
    }
    assert_equal old_count, User.count
    #assert_response :forbidden
  end

  def test_admin_should_destroy_librarian
    sign_in users(:admin)
    old_count = User.count
    delete :destroy, :id => users(:librarian2).username
    assert_equal old_count-1, User.count
    assert_redirected_to users_url
  end

  protected
  def create_user(options = {})
    post :create, :user => { :username => 'quire', :email => 'quire@example.com',
      :email_confirmation => 'quire@example.com', :password => 'quirequire', :password_confirmation => 'quirequire', :patron_id => 6, :user_number => '00008' }.merge(options)
  end

  def create_user_without_patron_id_and_name(options = {})
    post :create, :user => { :username => 'quire', :email => 'quire@example.com',
      :email_confirmation => 'quire@example.com', :password => 'quirequire', :password_confirmation => 'quirequire', :user_number => '00008' }.merge(options)
  end

  def create_user_without_patron_id(options = {})
    post :create, :user => { :username => 'quire', :email => 'quire@example.com',
      :email_confirmation => 'quire@example.com', :password => 'quirequire', :password_confirmation => 'quirequire', :user_number => '00008', :first_name => 'quire', :last_name => 'quire' }.merge(options)
  end

end
