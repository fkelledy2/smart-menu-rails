class AddDiffContentToMenuSourceChangeReviews < ActiveRecord::Migration[7.1]
  def change
    add_column :menu_source_change_reviews, :diff_content, :text
    add_column :menu_source_change_reviews, :diff_status, :integer, default: 0, null: false
  end
end
