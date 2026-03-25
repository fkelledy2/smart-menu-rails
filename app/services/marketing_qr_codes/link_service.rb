# frozen_string_literal: true

module MarketingQrCodes
  # Links a MarketingQrCode to a restaurant (and optionally a menu / tablesetting).
  # Idempotently finds or creates the corresponding Smartmenu record.
  #
  # Usage:
  #   result = MarketingQrCodes::LinkService.call(
  #     marketing_qr_code: qr,
  #     restaurant: restaurant,
  #     menu: menu,           # optional
  #     tablesetting: table,  # optional
  #   )
  #   result.success? # => true / false
  #   result.error    # => string message on failure
  class LinkService
    Result = Struct.new(:success?, :error, :marketing_qr_code, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(marketing_qr_code:, restaurant:, menu: nil, tablesetting: nil)
      @qr           = marketing_qr_code
      @restaurant   = restaurant
      @menu         = menu
      @tablesetting = tablesetting
    end

    def call
      return Result.new(success?: false, error: 'Marketing QR code not found') unless @qr
      return Result.new(success?: false, error: 'Restaurant is required') unless @restaurant

      ActiveRecord::Base.transaction do
        smartmenu = find_or_create_smartmenu!
        @qr.update!(
          restaurant: @restaurant,
          menu: @menu,
          tablesetting: @tablesetting,
          smartmenu: smartmenu,
          status: :linked,
        )
      end

      Result.new(success?: true, marketing_qr_code: @qr)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, error: e.message)
    rescue StandardError => e
      Rails.logger.error("[MarketingQrCodes::LinkService] #{e.class}: #{e.message}")
      Result.new(success?: false, error: 'An unexpected error occurred')
    end

    private

    def find_or_create_smartmenu!
      scope = Smartmenu.where(restaurant_id: @restaurant.id)

      scope = if @menu && @tablesetting
                # Fully qualified: restaurant + menu + table
                scope.where(menu_id: @menu.id, tablesetting_id: @tablesetting.id)
              elsif @menu
                # Menu-wide (no table)
                scope.where(menu_id: @menu.id, tablesetting_id: nil)
              else
                # Restaurant-wide (no menu or table)
                scope.where(menu_id: nil, tablesetting_id: nil)
              end

      existing = scope.first
      return existing if existing

      Smartmenu.create!(
        restaurant: @restaurant,
        menu: @menu,
        tablesetting: @tablesetting,
        slug: generate_slug,
      )
    end

    def generate_slug
      base = [@restaurant.name, @menu&.name, @tablesetting&.name]
        .compact
        .map { |s| s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/(^-|-$)/, '') }
        .join('-')
      slug = base.presence || 'menu'
      # Ensure uniqueness
      candidate = slug
      suffix    = 0
      while Smartmenu.exists?(slug: candidate)
        suffix += 1
        candidate = "#{slug}-#{suffix}"
      end
      candidate
    end
  end
end
