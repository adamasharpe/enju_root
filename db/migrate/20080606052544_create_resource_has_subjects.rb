class CreateResourceHasSubjects < ActiveRecord::Migration
  def self.up
    create_table :resource_has_subjects do |t|
      t.references :subject, :polymorphic => true
      t.references :subjectable, :polymorphic => true
      t.integer :work_id #, :null => false

      t.timestamps
    end
    add_index :resource_has_subjects, :subject_id
    add_index :resource_has_subjects, :subjectable_id
    add_index :resource_has_subjects, :work_id
  end

  def self.down
    drop_table :resource_has_subjects
  end
end
