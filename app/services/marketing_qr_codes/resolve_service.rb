# frozen_string_literal: true

module MarketingQrCodes
  # Resolves a marketing QR token to an action the controller should take.
  #
  # Returns a Result with one of three outcomes:
  #   :redirect_to_smartmenu  — linked; redirect to /t/:public_token
  #   :holding                — unlinked; render holding page or redirect to holding_url
  #   :not_found              — token does not exist
  #
  # Usage:
  #   result = MarketingQrCodes::ResolveService.call(token: 'some-uuid')
  #   case result.outcome
  #   when :redirect_to_smartmenu then redirect_to table_link_path(result.smartmenu_public_token)
  #   when :holding               then ...
  #   when :not_found             then render_404
  #   end
  class ResolveService
    Result = Struct.new(:outcome, :qr, :smartmenu_public_token, :holding_url, keyword_init: true)

    def self.call(token:)
      new(token:).call
    end

    def initialize(token:)
      @token = token.to_s.strip
    end

    def call
      qr = MarketingQrCode.find_by(token: @token)
      return Result.new(outcome: :not_found) unless qr

      case qr.status
      when 'linked'
        smartmenu = qr.smartmenu
        return Result.new(outcome: :not_found) unless smartmenu

        Result.new(
          outcome: :redirect_to_smartmenu,
          qr:,
          smartmenu_public_token: smartmenu.public_token,
        )
      when 'unlinked'
        Result.new(
          outcome: :holding,
          qr:,
          holding_url: qr.effective_holding_url,
        )
      else
        # archived — treat as not found
        Result.new(outcome: :not_found)
      end
    end
  end
end
