require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :users, :roles, :roles_users, :patrons, :libraries, :checkouts, :checkins, :patron_types, :advertisements, :tags, :taggings,
    :manifestations, :manifestation_forms, :expressions, :embodies, :works, :realizes, :creates, :reifies, :produces,
    :people, :corporate_bodies, :families

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  #def test_should_allow_signup
  #  assert_difference 'User.count' do
  #    create_user
  #    assert_response :redirect
  #  end
  #end

  def test_user_should_not_allow_signup
    login_as :user1
    assert_no_difference 'User.count' do
      create_user
      assert_response :forbidden
    end
  end

  def test_librarian_should_not_allow_signup_without_patron_id
    login_as :librarian1
    assert_no_difference 'User.count' do
      create_user_without_patron_id
      assert_response :missing
    end
  end

  def test_librarian_should_require_login_on_signup
    login_as :librarian1
    assert_no_difference 'User.count' do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end

  def test_librarian_should_not_require_password_on_signup
    login_as :librarian1
    assert_difference 'User.count' do
      create_user(:password => nil)
      #assert assigns(:user).errors.on(:password)
      #assert_response :success
      assert_response :redirect
      assert_redirected_to user_url(assigns(:user).login)
    end
  end

  def test_librarian_should_not_require_password_confirmation_on_signup
    login_as :librarian1
    assert_difference 'User.count' do
      create_user(:password_confirmation => nil)
      #assert assigns(:user).errors.on(:password_confirmation)
      #assert_response :success
      assert_response :redirect
      assert_redirected_to user_url(assigns(:user).login)
    end
  end

  def test_librarian_should_not_require_email_on_signup
    login_as :librarian1
    assert_difference 'User.count' do
      create_user(:email => nil)
      #assert assigns(:user).errors.on(:email)
      #assert_response :success
      assert_redirected_to user_url(assigns(:user).login)
    end
  end
  
  def test_guest_should_not_get_index
    get :index
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  def test_user_should_not_get_index
    login_as :user1
    get :index
    assert_response :forbidden
  end

  def test_librarian_should_get_index
    login_as :librarian1
    get :index
    assert_response :success
    assert assigns(:users)
  end

  def test_guest_should_not_update_user
    put :update, :id => 'admin', :user => { }
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  def test_user_should_update_myself
    login_as :user1
    put :update, :id => users(:user1).login, :user => { }
    assert_redirected_to user_url(assigns(:user).login)
  end

  def test_user_should_not_update_myself_without_login
    login_as :user1
    put :update, :id => users(:user1).login, :user => {:login => ""}
    assert_redirected_to user_url(assigns(:user).login)
    assert_equal assigns(:user).login, users(:user1).login
  end

  def test_user_should_update_myself_without_email
    login_as :user1
    put :update, :id => users(:user1).login, :user => {:email => ""}
    #assert_response :success
    assert_redirected_to user_url(assigns(:user).login)
  end

  def test_user_should_update_my_password
    login_as :user1
    put :update, :id => users(:user1).login, :user => {:email => 'user1@library.example.jp', :old_password => 'user1password', :password => 'new_user1', :password_confirmation => 'new_user1'}
    assert_redirected_to user_url(assigns(:user).login)
    assert_equal 'User was successfully updated.', flash[:notice]
  end

  def test_user_should_not_update_my_password_without_current_password
    login_as :user1
    put :update, :id => users(:user1).login, :user => {:email => 'user1@library.example.jp', :old_password => 'wrong password', :password => 'new_user1', :password_confirmation => 'new_user1'}
    assert_redirected_to edit_user_url(assigns(:user).login)
    assert_equal 'Wrong password.', flash[:notice]
  end

  def test_user_should_update_not_my_password_without_password_confirmation
    login_as :user1
    put :update, :id => users(:user1).login, :user => {:email => 'user1@library.example.jp', :old_password => 'user1password', :password => 'new_user1', :password_confirmation => 'wrong password'}
    assert_redirected_to edit_user_url(assigns(:user).login)
    assert_equal 'Password mismatch.', flash[:notice]
  end

  def test_user_should_not_update_other_user
    login_as :user1
    put :update, :id => users(:user2).login, :user => { }
    assert_response :forbidden
  end

  def test_librarian_should_update_other_user
    login_as :librarian1
    put :update, :id => users(:user1).login, :user => {:user_number => '00003'}
    assert_redirected_to user_url(assigns(:user).login)
    #assert_nil assigns(:user).errors
  end

  def test_guest_should_not_get_new
    get :new, :patron_id => 6
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  def test_everyone_should_not_get_new_without_patron_id
    login_as :admin
    get :new
    assert_response :redirect
    assert_redirected_to patrons_url
  end

  def test_user_should_not_get_new
    login_as :user1
    get :new, :patron_id => 6
    assert_response :forbidden
  end

  def test_librarian_should_get_new
    login_as :librarian1
    get :new, :patron_id => 6
    assert_response :success
  end

  def test_guest_should_not_show_user
    get :show, :id => 1
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  def test_user_should_show_my_user
    login_as :user1
    get :show, :id => users(:user1).login
    assert_response :success
  end

  def test_user_should_show_other_user
    login_as :user1
    get :show, :id => users(:admin).login
    assert_response :success
  end

  def test_everyone_should_not_show_missing_user
    login_as :admin
    get :show, :id => 100
    assert_response :missing
  end

  def test_guest_should_not_edit_user
    get :edit, :id => 1
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  def test_everyone_should_not_edit_missing_user
    login_as :admin
    get :edit, :id => 100
    assert_response :missing
  end

  def test_user_should_edit_my_user
    login_as :user1
    get :edit, :id => users(:user1).login
    assert_response :success
  end

  def test_user_should_not_show_other_user
    login_as :user1
    get :edit, :id => users(:user2).login
    assert_response :forbidden
  end

  def test_librarian_should_edit_other_user
    login_as :librarian1
    get :edit, :id => users(:user1).login
    assert_response :success
  end

  def test_guest_should_not_destroy_user
    old_count = User.count
    delete :destroy, :id => 1
    assert_equal old_count, User.count
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  def test_user_should_not_destroy_myself
    login_as :user1
    old_count = User.count
    delete :destroy, :id => users(:user1).login
    assert_equal old_count, User.count
    assert_response :forbidden
  end

  def test_user_should_not_destroy_other_user
    login_as :user1
    old_count = User.count
    delete :destroy, :id => users(:user2).login
    assert_equal old_count, User.count
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_myself
    login_as :librarian1
    old_count = User.count
    delete :destroy, :id => users(:librarian1).login
    assert_equal old_count, User.count
    assert_response :forbidden
  end

  def test_librarian_should_destroy_user
    login_as :librarian1
    old_count = User.count
    delete :destroy, :id => users(:user2).login
    assert_equal old_count-1, User.count
    assert_redirected_to users_url
  end

  def test_librarian_should_not_destroy_user_who_has_items_not_checked_in
    login_as :librarian1
    old_count = User.count
    delete :destroy, :id => users(:user1).login
    assert_equal old_count, User.count
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_librarian
    login_as :librarian1
    old_count = User.count
    delete :destroy, :id => users(:librarian2).login
    assert_equal old_count, User.count
    assert_response :forbidden
  end

  def test_librarian_should_not_destroy_admin
    login_as :librarian1
    old_count = User.count
    delete :destroy, :id => users(:admin).login
    assert_equal old_count, User.count
    assert_response :forbidden
  end

  def test_admin_should_destroy_librarian
    login_as :admin
    old_count = User.count
    delete :destroy, :id => users(:librarian2).login
    assert_equal old_count-1, User.count
    assert_redirected_to users_url
  end

  protected
    def create_user(options = {})
      post :create, :user => { :login => 'quire', :email => 'quire@example.com',
        :password => 'quirequire', :password_confirmation => 'quirequire', :patron_id => 6, :patron_type => 'Person', :user_number => '00006' }.merge(options)
    end

    def create_user_without_patron_id(options = {})
      post :create, :user => { :login => 'quire', :email => 'quire@example.com',
        :password => 'quirequire', :password_confirmation => 'quirequire', :user_number => '00006' }.merge(options)
    end
end
