class MenuVersionActivationService
  def self.activate!(menu_version:, starts_at: nil, ends_at: nil)
    raise ArgumentError, 'menu_version is required' unless menu_version

    menu = menu_version.menu

    menu.with_lock do
      if starts_at.present? || ends_at.present?
        menu_version.update!(
          is_active: false,
          starts_at: starts_at,
          ends_at: ends_at,
        )
      else
        MenuVersion.where(menu_id: menu.id, is_active: true).where.not(id: menu_version.id).update_all(is_active: false)
        menu_version.update!(
          is_active: true,
          starts_at: nil,
          ends_at: nil,
        )
      end
    end

    menu_version
  end
end
