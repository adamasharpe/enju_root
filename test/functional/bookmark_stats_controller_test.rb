require 'test_helper'

class BookmarkStatsControllerTest < ActionController::TestCase
  fixtures :bookmark_stats, :users

  test "guest should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:bookmark_stats)
  end

  test "guest should not get new" do
    get :new
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  test "user should not get new" do
    login_as :user1
    get :new
    assert_response :forbidden
  end

  test "librarian should get new" do
    login_as :librarian1
    get :new
    assert_response :success
  end

  test "guest should not create bookmark_stat" do
    assert_no_difference('BookmarkStat.count') do
      post :create, :bookmark_stat => { }
    end

    assert_response :redirect
    assert_redirected_to new_session_url
  end

  test "user should not create bookmark_stat" do
    login_as :user1
    assert_no_difference('BookmarkStat.count') do
      post :create, :bookmark_stat => { }
    end

    assert_response :forbidden
  end

  test "librarian should create bookmark_stat" do
    login_as :librarian1
    assert_difference('BookmarkStat.count') do
      post :create, :bookmark_stat => {:start_date => Time.zone.now, :end_date => Time.zone.now.tomorrow}
    end

    assert_redirected_to bookmark_stat_path(assigns(:bookmark_stat))
  end

  test "guest should show bookmark_stat" do
    get :show, :id => bookmark_stats(:one).id
    assert_response :success
  end

  test "guest should not get edit" do
    get :edit, :id => bookmark_stats(:one).id
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  test "user should not get edit" do
    login_as :user1
    get :edit, :id => bookmark_stats(:one).id
    assert_response :forbidden
  end

  test "librarian should get edit" do
    login_as :librarian1
    get :edit, :id => bookmark_stats(:one).id
    assert_response :success
  end

  test "guest should not update bookmark_stat" do
    put :update, :id => bookmark_stats(:one).id, :bookmark_stat => { }
    assert_redirected_to new_session_url
  end

  test "user should not update bookmark_stat" do
    login_as :user1
    put :update, :id => bookmark_stats(:one).id, :bookmark_stat => { }
    assert_response :forbidden
  end

  test "librarian should update bookmark_stat" do
    login_as :librarian1
    put :update, :id => bookmark_stats(:one).id, :bookmark_stat => { }
    assert_redirected_to bookmark_stat_path(assigns(:bookmark_stat))
  end

  test "guest_should not destroy bookmark_stat" do
    assert_no_difference('BookmarkStat.count') do
      delete :destroy, :id => bookmark_stats(:one).id
    end

    assert_redirected_to new_session_url
  end

  test "user should not destroy bookmark_stat" do
    login_as :user1
    assert_no_difference('BookmarkStat.count') do
      delete :destroy, :id => bookmark_stats(:one).id
    end

    assert_response :forbidden
  end

  test "librarian should destroy bookmark_stat" do
    login_as :librarian1
    assert_difference('BookmarkStat.count', -1) do
      delete :destroy, :id => bookmark_stats(:one).id
    end

    assert_redirected_to bookmark_stats_path
  end
end
