class AddSequenceToTips < ActiveRecord::Migration[7.1]
  def change
      add_column :tips, :sequence, :integer
  end
end
