class FixOrderitemMenuitemFkOnDelete < ActiveRecord::Migration[7.2]
  def change
    # ordritems retain their record even if the menuitem is later removed from the menu
    remove_foreign_key :ordritems, :menuitems
    add_foreign_key :ordritems, :menuitems, on_delete: :nullify
  end
end
