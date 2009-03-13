require 'test_helper'

class UserReserveStatsControllerTest < ActionController::TestCase
  fixtures :user_reserve_stats, :users

  test "guest should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:user_reserve_stats)
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

  test "guest should not create user_reserve_stat" do
    assert_no_difference('UserReserveStat.count') do
      post :create, :user_reserve_stat => { }
    end

    assert_response :redirect
    assert_redirected_to new_session_url
  end

  test "user should not create user_reserve_stat" do
    login_as :user1
    assert_no_difference('UserReserveStat.count') do
      post :create, :user_reserve_stat => { }
    end

    assert_response :forbidden
  end

  test "librarian should create user_reserve_stat" do
    login_as :librarian1
    assert_difference('UserReserveStat.count') do
      post :create, :user_reserve_stat => {:start_date => Time.zone.now, :end_date => Time.zone.now.tomorrow}
    end

    assert_redirected_to user_reserve_stat_path(assigns(:user_reserve_stat))
  end

  test "guest should show user_reserve_stat" do
    get :show, :id => user_reserve_stats(:one).id
    assert_response :success
  end

  test "guest should not get edit" do
    get :edit, :id => user_reserve_stats(:one).id
    assert_response :redirect
    assert_redirected_to new_session_url
  end

  test "user should not get edit" do
    login_as :user1
    get :edit, :id => user_reserve_stats(:one).id
    assert_response :forbidden
  end

  test "librarian should get edit" do
    login_as :librarian1
    get :edit, :id => user_reserve_stats(:one).id
    assert_response :success
  end

  test "guest should not update user_reserve_stat" do
    put :update, :id => user_reserve_stats(:one).id, :user_reserve_stat => { }
    assert_redirected_to new_session_url
  end

  test "user should not update user_reserve_stat" do
    login_as :user1
    put :update, :id => user_reserve_stats(:one).id, :user_reserve_stat => { }
    assert_response :forbidden
  end

  test "librarian should update user_reserve_stat" do
    login_as :librarian1
    put :update, :id => user_reserve_stats(:one).id, :user_reserve_stat => { }
    assert_redirected_to user_reserve_stat_path(assigns(:user_reserve_stat))
  end

  test "guest_should not destroy user_reserve_stat" do
    assert_no_difference('UserReserveStat.count') do
      delete :destroy, :id => user_reserve_stats(:one).id
    end

    assert_redirected_to new_session_url
  end

  test "user should not destroy user_reserve_stat" do
    login_as :user1
    assert_no_difference('UserReserveStat.count') do
      delete :destroy, :id => user_reserve_stats(:one).id
    end

    assert_response :forbidden
  end

  test "librarian should destroy user_reserve_stat" do
    login_as :librarian1
    assert_difference('UserReserveStat.count', -1) do
      delete :destroy, :id => user_reserve_stats(:one).id
    end

    assert_redirected_to user_reserve_stats_path
  end
end
