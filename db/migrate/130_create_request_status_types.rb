class CreateRequestStatusTypes < ActiveRecord::Migration
  def self.up
    create_table :request_status_types do |t|
      t.string :name
      t.string :display_name
      t.text :note
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :request_status_types
  end
end
