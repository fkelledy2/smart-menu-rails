class AddPlanToUser < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :plan, foreign_key: false
  end
end
