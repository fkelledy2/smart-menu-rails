class Menuparticipant < ApplicationRecord
  belongs_to :smartmenu

  # Normalize locale to lowercase before save (I18n expects :en, :it, not :EN, :IT)
  before_save :normalize_locale

  private

  def normalize_locale
    self.preferredlocale = preferredlocale.downcase if preferredlocale.present?
  end
end
