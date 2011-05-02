class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table "roles" do |t|
      t.column :name, :string, :null => false
      t.column :display_name, :string
      t.column :note, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.integer :score, :default => 0, :null => false
      t.integer :position
    end
    
    # generate the join table
    create_table "roles_users", :id => false do |t|
      t.column "role_id", :integer, :null => false
      t.column "user_id", :integer, :null => false
    end
    add_index "roles_users", "role_id"
    add_index "roles_users", "user_id"
  end

  def self.down
    drop_table "roles"
    drop_table "roles_users"
  end
end
