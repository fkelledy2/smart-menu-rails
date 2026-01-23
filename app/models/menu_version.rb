class MenuVersion < ApplicationRecord
  belongs_to :menu
  belongs_to :created_by_user, class_name: 'User', optional: true

  validates :menu, presence: true
  validates :version_number, presence: true
  validates :snapshot_json, presence: true
  validates :is_active, inclusion: { in: [true, false] }

  validates :version_number, uniqueness: { scope: :menu_id }

  attr_readonly :menu_id, :version_number, :snapshot_json, :created_by_user_id

  def self.create_from_menu!(menu:, user: nil)
    raise ArgumentError, 'menu is required' unless menu

    menu.with_lock do
      next_version_number = MenuVersion.where(menu_id: menu.id).maximum(:version_number).to_i + 1
      snapshot = MenuVersionSnapshotService.snapshot_for(menu)

      MenuVersion.create!(
        menu: menu,
        version_number: next_version_number,
        snapshot_json: snapshot,
        created_by_user: user,
      )
    end
  end
end
