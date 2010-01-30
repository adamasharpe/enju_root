require 'test_helper'

class EventImportFilesControllerTest < ActionController::TestCase
  setup :activate_authlogic
  fixtures :event_import_files, :users, :roles, :patrons, :db_files,
    :user_groups, :libraries, :library_groups, :patron_types, :languages,
    :events, :event_categories,
    :imported_objects

  def test_guest_should_not_get_index
    get :index
    assert_response :redirect
    assert_redirected_to new_user_session_url
    assert_nil assigns(:event_import_files)
  end

  def test_user_should_not_get_index
    UserSession.create users(:user1)
    get :index
    assert_response :forbidden
    assert_nil assigns(:event_import_files)
  end

  def test_librarian_should_get_index
    UserSession.create users(:librarian1)
    get :index
    assert_response :success
    assert_not_nil assigns(:event_import_files)
  end

  def test_guest_should_not_get_new
    get :new
    assert_response :redirect
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

  def test_guest_should_not_create_event_import_file
    assert_no_difference('EventImportFile.count') do
      post :create, :event_import_file => { }
    end

    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_event_import_file
    UserSession.create users(:user1)
    assert_no_difference('EventImportFile.count') do
      post :create, :event_import_file => { }
    end

    assert_response :forbidden
  end

  def test_librarian_should_create_event_import_file
    old_event_count = Event.count
    UserSession.create users(:librarian1)
    assert_difference('EventImportFile.count') do
      post :create, :event_import_file => {:event_import => ActionController::TestUploadedFile.new("#{RAILS_ROOT}/public/event_import_file_sample1.tsv") }
    end

    assigns(:event_import_file).import
    assert_equal old_event_count + 2, Event.count
    assert_equal 'librarian1', assigns(:event_import_file).user.login
    assert_redirected_to event_import_file_url(assigns(:event_import_file))
  end

  def test_guest_should_not_show_event_import_file
    get :show, :id => event_import_files(:event_import_file_00003).id
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_show_event_import_file
    UserSession.create users(:user1)
    get :show, :id => event_import_files(:event_import_file_00003).id
    assert_response :forbidden
  end

  def test_librarian_should_show_event_import_file
    UserSession.create users(:librarian1)
    get :show, :id => event_import_files(:event_import_file_00003).id
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => event_import_files(:event_import_file_00003).id
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_get_edit
    UserSession.create users(:user1)
    get :edit, :id => event_import_files(:event_import_file_00003).id
    assert_response :forbidden
  end

  def test_librarian_should_get_edit
    UserSession.create users(:librarian1)
    get :edit, :id => event_import_files(:event_import_file_00003).id
    assert_response :success
  end

  def test_guest_should_not_update_event_import_file
    put :update, :id => event_import_files(:event_import_file_00003).id, :event_import_file => { }
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_update_event_import_file
    UserSession.create users(:user1)
    put :update, :id => event_import_files(:event_import_file_00003).id, :event_import_file => { }
    assert_response :forbidden
  end

  def test_librarian_should_update_event_import_file
    UserSession.create users(:librarian1)
    put :update, :id => event_import_files(:event_import_file_00003).id, :event_import_file => { }
    assert_redirected_to event_import_file_url(assigns(:event_import_file))
  end

  def test_guest_should_not_destroy_event_import_file
    assert_no_difference('EventImportFile.count') do
      delete :destroy, :id => event_import_files(:event_import_file_00003).id
    end

    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_event_import_file
    UserSession.create users(:user1)
    assert_no_difference('EventImportFile.count') do
      delete :destroy, :id => event_import_files(:event_import_file_00003).id
    end

    assert_response :forbidden
  end

  def test_librarian_should_destroy_event_import_file
    UserSession.create users(:librarian1)
    assert_difference('EventImportFile.count', -1) do
      delete :destroy, :id => event_import_files(:event_import_file_00003).id
    end

    assert_redirected_to event_import_files_path
  end
end
