class CreateNewsPosts < ActiveRecord::Migration
  def self.up
    create_table :news_posts do |t|
      t.text :title
      t.text :body
      t.integer :user_id
      t.integer :required_score
      t.datetime :start_date
      t.datetime :end_date
      t.text :note
      t.integer :position

      t.timestamps
    end
    add_index :news_posts, :user_id
  end

  def self.down
    drop_table :news_posts
  end
end
