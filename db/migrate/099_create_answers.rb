class CreateAnswers < ActiveRecord::Migration
  def self.up
    create_table :answers do |t|
      t.integer :user_id
      t.integer :question_id
      t.text :body
      t.timestamps
      t.datetime :deleted_at
    end
    add_index :answers, :user_id
    add_index :answers, :question_id
  end

  def self.down
    drop_table :answers
  end
end
