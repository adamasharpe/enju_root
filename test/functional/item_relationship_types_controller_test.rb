require 'test_helper'

class ItemRelationshipTypesControllerTest < ActionController::TestCase
  fixtures :item_relationship_types

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:item_relationship_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create item_relationship_type" do
    assert_difference('ItemRelationshipType.count') do
      post :create, :item_relationship_type => { }
    end

    assert_redirected_to item_relationship_type_path(assigns(:item_relationship_type))
  end

  test "should show item_relationship_type" do
    get :show, :id => item_relationship_types(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => item_relationship_types(:one).id
    assert_response :success
  end

  test "should update item_relationship_type" do
    put :update, :id => item_relationship_types(:one).id, :item_relationship_type => { }
    assert_redirected_to item_relationship_type_path(assigns(:item_relationship_type))
  end

  test "should destroy item_relationship_type" do
    assert_difference('ItemRelationshipType.count', -1) do
      delete :destroy, :id => item_relationship_types(:one).id
    end

    assert_redirected_to item_relationship_types_path
  end
end
