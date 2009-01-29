class CreateEmbodies < ActiveRecord::Migration
  def self.up
    create_table :embodies do |t|
      t.integer :expression_id, :null => false
      t.integer :manifestation_id, :null => false
      t.string :type
      t.integer :position
      t.timestamps
    end
    add_index :embodies, :expression_id
    add_index :embodies, :manifestation_id
    add_index :embodies, :type
  end

  def self.down
    drop_table :embodies
  end
end
