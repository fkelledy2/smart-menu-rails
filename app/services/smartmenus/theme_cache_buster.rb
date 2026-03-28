# frozen_string_literal: true

module Smartmenus
  # Invalidates all fragment cache entries keyed on a given Smartmenu's theme.
  # Called synchronously from the Smartmenu after_save callback when theme changes.
  # Redis SCAN + DEL via delete_matched is fast enough for synchronous use.
  class ThemeCacheBuster
    def initialize(smartmenu)
      @smartmenu = smartmenu
    end

    def call
      Rails.cache.delete_matched(cache_key_pattern)
    end

    private

    def cache_key_pattern
      "views/*smartmenu*#{@smartmenu.id}*"
    end
  end
end
