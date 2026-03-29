class SmartmenuPreviewToken
  TTL = 4.hours

  def self.generate(mode:, menu_id:)
    payload = { mode: mode.to_s, menu_id: menu_id, exp: TTL.from_now.to_i }
    Rails.application.message_verifier(:smartmenu_preview).generate(payload)
  end

  def self.decode(token)
    return nil if token.blank?

    payload = Rails.application.message_verifier(:smartmenu_preview).verify(token)
    return nil if Time.current.to_i > payload[:exp]

    payload
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageVerifier::InvalidMessage
    nil
  end
end
