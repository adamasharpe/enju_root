require 'test_helper'

class BookmarksControllerTest < ActionController::TestCase
  setup :activate_authlogic
  fixtures :bookmarks
  fixtures :works, :form_of_works, :expressions, :content_types, :frequencies, :languages, :manifestations, :carrier_types, :tags, :taggings, :shelves, :items, :circulation_statuses,
    :creates, :realizes, :produces, :owns,
    :reifies, :embodies, :exemplifies
  fixtures :users, :patrons, :patron_types
  fixtures :roles

  def test_guest_should_not_get_index
    get :index
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_get_index_without_user_id
    UserSession.create users(:user1)
    get :index
    assert_response :redirect
    assert_redirected_to user_bookmarks_url(users(:user1).login)
  end

  def test_librarian_should_get_index_without_user_id
    UserSession.create users(:librarian1)
    get :index
    assert_response :success
    assert assigns(:bookmarks)
  end

  def test_admin_should_get_index_without_user_id
    UserSession.create users(:admin)
    get :index
    assert_response :success
    assert assigns(:bookmarks)
  end

  def test_user_should_get_my_index
    UserSession.create users(:user1)
    get :index, :user_id => users(:user1).login
    assert_response :success
    assert assigns(:bookmarks)
  end

  def test_user_should_get_other_public_index
    UserSession.create users(:user1)
    get :index, :user_id => users(:admin).login
    assert_response :success
    assert assigns(:bookmarks)
  end

  def test_user_should_not_get_other_private_index
    UserSession.create users(:user2)
    get :index, :user_id => users(:user1).login
    assert_response :forbidden
    assert_nil assigns(:bookmarks)
  end

  def test_guest_should_not_get_new
    get :new
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_new_without_user_id
    UserSession.create users(:user1)
    get :new
    #assert_response :forbidden
    assert_response :missing
  end
  
  def test_user_should_not_get_new_with_other_user_id
    UserSession.create users(:user1)
    get :new, :user_id => users(:admin).login
    assert_response :forbidden
  end
  
  def test_user_should_not_get_my_new_without_url
    UserSession.create users(:user1)
    get :new, :user_id => users(:user1).login
    assert_response :success
  end
  
  def test_user_should_not_get_new_with_already_bookmarked_url
    UserSession.create users(:user1)
    get :new, :user_id => users(:user1).login, :url => 'http://www.slis.keio.ac.jp/'
    assert_response :redirect
    assert_equal 'This resource is already bookmarked.', flash[:notice]
    assert_redirected_to manifestation_url(assigns(:manifestation))
  end
  
  def test_user_should_get_my_new_with_external_url
    UserSession.create users(:user1)
    get :new, :user_id => users(:user1).login, :title => 'example', :url => 'http://example.com'
    assert_response :success
  end
  
  def test_user_should_not_get_my_new_with_internal_url
    UserSession.create users(:user1)
    get :new, :user_id => users(:user1).login, :url => LibraryGroup.url
    assert_response :redirect
    assert_redirected_to LibraryGroup.url
  end
  
  def test_guest_should_not_create_bookmark
    old_count = Bookmark.count
    post :create, :bookmark => {:title => 'example', :url => 'http://example.com'}
    assert_equal old_count, Bookmark.count
    
    assert_redirected_to new_user_session_url
  end

  def test_user_should_create_bookmark
    UserSession.create users(:user1)
    old_count = Bookmark.count
    post :create, :bookmark => {:title => 'example', :url => 'http://example.com/'}, :user_id => users(:user1).login
    assert_equal old_count+1, Bookmark.count
    #assert assigns(:bookmark).manifestation
    #assert_nil assigns(:bookmark).manifestation.items.first.item_identifier
    
    assert_redirected_to bookmark_url(assigns(:bookmark))
    assigns(:bookmark).remove_from_index!
  end

  def test_user_should_create_bookmark_with_local_url
    UserSession.create users(:user1)
    old_count = Bookmark.count
    post :create, :bookmark => {:title => 'example', :url => "#{LibraryGroup.url}manifestations/10"}
    #assert assigns(:bookmark).manifestation
    #assert_nil assigns(:bookmark).manifestation.items.first.item_identifier
    
    assert_redirected_to bookmark_url(assigns(:bookmark))
    assigns(:bookmark).remove_from_index!
    assert_equal old_count+1, Bookmark.count
  end

  def test_user_should_not_create_other_users_bookmark
    UserSession.create users(:user1)
    assert_difference('Bookmark.count') do
      post :create, :bookmark => {:user_id => users(:user2).id, :title => 'example', :url => 'http://example.com/'}, :user_id => users(:user2).login
    end
    
    assert_response :redirect
    assert_redirected_to bookmark_url(assigns(:bookmark))
    assert_equal users(:user1), assigns(:bookmark).user
    assigns(:bookmark).remove_from_index!
  end

  def test_user_should_create_bookmark_with_tag_list
    UserSession.create users(:user1)
    old_count = Bookmark.count
    old_tag_count = Tag.count
    post :create, :bookmark => {:tag_list => 'search', :title => 'example', :url => 'http://example.com/'}, :user_id => users(:user1).login
    assert_equal old_count+1, Bookmark.count
    
    assert_equal ['search'], assigns(:bookmark).tag_list
    assert_equal old_tag_count+1, Tag.count
    #assert_equal 1, assigns(:bookmark).manifestation.items.size
    assert_redirected_to bookmark_url(assigns(:bookmark))
    assigns(:bookmark).remove_from_index!
  end

  def test_user_should_create_bookmark_with_tag_list_include_wide_space
    UserSession.create users(:user1)
    old_count = Bookmark.count
    post :create, :bookmark => {:tag_list => 'タグの　テスト', :title => 'example', :url => 'http://example.com/'}, :user_id => users(:user1).login
    assert_equal old_count+1, Bookmark.count
    
    assert_equal ['タグの', 'テスト'], assigns(:bookmark).tag_list
    #assert_nil assigns(:bookmark).manifestation.items.first.item_identifier
    #assert_equal 1, assigns(:bookmark).manifestation.items.size
    assert_redirected_to bookmark_url(assigns(:bookmark))
    assigns(:bookmark).remove_from_index!
  end

  def test_user_should_not_create_bookmark_without_url
    UserSession.create users(:user1)
    old_count = Bookmark.count
    post :create, :bookmark => {}, :user_id => users(:user1).login
    assert_equal old_count, Bookmark.count
    
    assert_equal 'Invalid URL.', flash[:notice]
  end

  def test_user_should_not_create_bookmark_already_bookmarked
    UserSession.create users(:user1)
    old_count = Bookmark.count
    post :create, :bookmark => {:user_id => users(:user1).id, :url => 'http://www.slis.keio.ac.jp/'}, :user_id => users(:user1).login
    assert_equal old_count, Bookmark.count
    
    assert_equal 'This resource is already bookmarked.', flash[:notice]
  end

  def test_guest_should_not_show_bookmark_without_user_id
    get :show, :id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_guest_should_not_show_bookmark_with_user_id
    get :show, :id => 5, :user_id => users(:user2).login
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_show_other_user_bookmark
    UserSession.create users(:user1)
    get :show, :id => 1, :user_id => users(:admin).login
    assert_response :forbidden
  end
  
  def test_user_should_show_my_bookmark
    UserSession.create users(:user1)
    get :show, :id => 3, :user_id => users(:user1).login
    assert_response :success
  end
  
  def test_librarian_should_show_other_user_bookmark
    UserSession.create users(:librarian1)
    get :show, :id => 3, :user_id => users(:user1).login
    assert_response :success
  end
  
  def test_guest_should_not_get_edit
    get :edit, :id => 1
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_not_get_edit_without_user_id
    UserSession.create users(:user1)
    get :edit, :id => 1
    assert_response :forbidden
  end
  
  def test_user_should_not_get_edit_other_user_bookmark
    UserSession.create users(:user1)
    get :edit, :id => 1, :user_id => users(:admin).login
    assert_response :forbidden
  end
  
  def test_user_should_get_edit
    UserSession.create users(:user1)
    get :edit, :id => 3, :user_id => users(:user1).login
    assert_response :success
  end
  
  def test_librarian_should_get_edit
    UserSession.create users(:librarian1)
    get :edit, :id => 3, :user_id => users(:user1).login
    assert_response :success
  end
  
  def test_librarian_should_get_edit_without_user
    UserSession.create users(:librarian1)
    get :edit, :id => 3
    assert_response :success
  end
  
  def test_guest_should_not_update_bookmark
    put :update, :id => 1, :user_id => users(:admin).login, :bookmark => { }
    assert_redirected_to new_user_session_url
  end
  
  def test_user_should_update_my_bookmark_without_user_id
    UserSession.create users(:user1)
    put :update, :id => 3, :bookmark => { }
    assert_response :redirect
    assert_redirected_to user_bookmark_url(users(:user1).login, assigns(:bookmark))
    assigns(:bookmark).remove_from_index!
  end

  def test_user_should_not_update_other_user_bookmark
    UserSession.create users(:user1)
    put :update, :id => 1, :user_id => users(:admin).login, :bookmark => { }
    assert_response :forbidden
  end

  def test_user_should_not_update_missing_bookmark
    UserSession.create users(:user1)
    put :update, :id => 100, :user_id => users(:user1).login, :bookmark => { }
    assert_response :missing
  end

  def test_user_should_update_without_manifestation_id
    UserSession.create users(:user1)
    put :update, :id => 3, :user_id => users(:user1).login, :bookmark => {:manifestation_id => nil}
    assert_response :redirect
    assert_redirected_to user_bookmark_url(users(:user1).login, assigns(:bookmark))
  end

  def test_user_should_update_bookmark
    UserSession.create users(:user1)
    put :update, :id => 3, :user_id => users(:user1).login, :bookmark => { }
    assert_response :redirect
    assert_redirected_to user_bookmark_url(users(:user1).login, assigns(:bookmark))
    assigns(:bookmark).remove_from_index!
  end
  
  def test_user_should_add_tags_to_bookmark
    UserSession.create users(:user1)
    put :update, :id => 3, :user_id => users(:user1).login, :bookmark => {:user_id => users(:user1).id, :tag_list => 'search', :title => 'test'}
    assert_redirected_to user_bookmark_url(users(:user1).login, assigns(:bookmark))
    assert_equal ['search'], assigns(:bookmark).tag_list
    assigns(:bookmark).remove_from_index!
  end
  
  def test_guest_should_not_destroy_bookmark
    old_count = Bookmark.count
    delete :destroy, :id => 1
    assert_equal old_count, Bookmark.count
    
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_destroy_my_bookmark
    UserSession.create users(:user1)
    old_count = Bookmark.count
    delete :destroy, :id => 3, :user_id => users(:user1).login
    assert_equal old_count-1, Bookmark.count
    
    assert_redirected_to user_bookmarks_url(users(:user1).login)
  end

  def test_user_should_not_destroy_other_bookmark
    UserSession.create users(:user1)
    old_count = Bookmark.count
    delete :destroy, :id => 1, :user_id => users(:admin).login
    assert_equal old_count, Bookmark.count
    
    assert_response :forbidden
  end
end
