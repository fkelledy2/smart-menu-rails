class SmartmenuPreviewToken
  TTL = 4.hours

  def self.generate(mode:, menu_id:)
    payload = { mode: mode.to_s, menu_id: menu_id, exp: TTL.from_now.to_i }
    Rails.application.message_verifier(:smartmenu_preview).generate(payload)
  end

  def self.decode(token)
    return nil if token.blank?

    payload = Rails.application.message_verifier(:smartmenu_preview).verify(token).with_indifferent_access
    return nil if payload[:exp].nil? || Time.current.to_i > payload[:exp]

    payload
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
    nil
  end
end
