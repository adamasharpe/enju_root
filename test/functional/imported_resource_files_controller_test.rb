require 'test_helper'

class ImportedResourceFilesControllerTest < ActionController::TestCase
  setup :activate_authlogic
  fixtures :imported_resource_files, :users, :roles, :patrons, :db_files,
    :user_groups, :libraries, :library_groups, :patron_types, :languages,
    :events, :event_categories, :circulation_statuses,
    :imported_objects

  def test_guest_should_not_get_index
    get :index
    assert_response :redirect
    assert_redirected_to new_user_session_url
    assert_nil assigns(:imported_resource_files)
  end

  def test_user_should_not_get_index
    UserSession.create users(:user1)
    get :index
    assert_response :forbidden
    assert_nil assigns(:imported_resource_files)
  end

  def test_librarian_should_get_index
    UserSession.create users(:librarian1)
    get :index
    assert_response :success
    assert_not_nil assigns(:imported_resource_files)
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

  def test_guest_should_not_create_imported_resource_file
    assert_no_difference('ImportedResourceFile.count') do
      post :create, :imported_resource_file => { }
    end

    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_create_imported_resource_file
    UserSession.create users(:user1)
    assert_no_difference('ImportedResourceFile.count') do
      post :create, :imported_resource_file => { }
    end

    assert_response :forbidden
  end

  def test_librarian_should_create_imported_resource_file
    UserSession.create users(:librarian1)
    old_patrons_count = Patron.count
    old_manifestations_count = Manifestation.count
    assert_difference('ImportedResourceFile.count') do
      post :create, :imported_resource_file => {:imported_resource => ActionController::TestUploadedFile.new("#{RAILS_ROOT}/public/imported_resource_file_sample1.tsv") }
    end
    # 後でバッチで処理する
    #assert_equal old_manifestations_count + 5, Manifestation.count
    #assert_equal old_patrons_count + 4, Patron.count

    assert_redirected_to imported_resource_file_path(assigns(:imported_resource_file))
  end

  def test_librarian_should_create_imported_resource_file_only_isbn
    UserSession.create users(:librarian1)
    old_patrons_count = Patron.count
    old_manifestations_count = Manifestation.count
    assert_difference('ImportedResourceFile.count') do
      post :create, :imported_resource_file => {:imported_resource => ActionController::TestUploadedFile.new("#{RAILS_ROOT}/public/isbn_sample.txt") }
    end
    # 後でバッチで処理する
    #assert_equal old_manifestations_count + 1, Manifestation.count
    #assert_equal old_patrons_count + 5, Patron.count

    assert_redirected_to imported_resource_file_path(assigns(:imported_resource_file))
  end

  def test_guest_should_not_show_imported_resource_file
    get :show, :id => imported_resource_files(:imported_resource_file_00003).id
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_show_imported_resource_file
    UserSession.create users(:user1)
    get :show, :id => imported_resource_files(:imported_resource_file_00003).id
    assert_response :forbidden
  end

  def test_librarian_should_show_imported_resource_file
    UserSession.create users(:librarian1)
    get :show, :id => imported_resource_files(:imported_resource_file_00003).id
    assert_response :success
  end

  def test_guest_should_not_get_edit
    get :edit, :id => imported_resource_files(:imported_resource_file_00003).id
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_get_edit
    UserSession.create users(:user1)
    get :edit, :id => imported_resource_files(:imported_resource_file_00003).id
    assert_response :forbidden
  end

  def test_librarian_should_get_edit
    UserSession.create users(:librarian1)
    get :edit, :id => imported_resource_files(:imported_resource_file_00003).id
    assert_response :success
  end

  def test_guest_should_not_update_imported_resource_file
    put :update, :id => imported_resource_files(:imported_resource_file_00003).id, :imported_resource_file => { }
    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_update_imported_resource_file
    UserSession.create users(:user1)
    put :update, :id => imported_resource_files(:imported_resource_file_00003).id, :imported_resource_file => { }
    assert_response :forbidden
  end

  def test_librarian_should_update_imported_resource_file
    UserSession.create users(:librarian1)
    put :update, :id => imported_resource_files(:imported_resource_file_00003).id, :imported_resource_file => { }
    assert_redirected_to imported_resource_file_path(assigns(:imported_resource_file))
  end

  def test_guest_should_not_destroy_imported_resource_file
    assert_no_difference('ImportedResourceFile.count') do
      delete :destroy, :id => imported_resource_files(:imported_resource_file_00003).id
    end

    assert_redirected_to new_user_session_url
  end

  def test_user_should_not_destroy_imported_resource_file
    UserSession.create users(:user1)
    assert_no_difference('ImportedResourceFile.count') do
      delete :destroy, :id => imported_resource_files(:imported_resource_file_00003).id
    end

    assert_response :forbidden
  end

  def test_librarian_should_destroy_imported_resource_file
    UserSession.create users(:librarian1)
    assert_difference('ImportedResourceFile.count', -1) do
      delete :destroy, :id => imported_resource_files(:imported_resource_file_00003).id
    end

    assert_redirected_to imported_resource_files_path
  end
end
