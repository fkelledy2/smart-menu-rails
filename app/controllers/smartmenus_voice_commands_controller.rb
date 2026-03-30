class SmartmenusVoiceCommandsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  before_action :ensure_voice_enabled

  def show
    smartmenu = find_smartmenu
    return head :not_found unless smartmenu

    vc = VoiceCommand.where(smartmenu: smartmenu, session_id: session.id.to_s).find_by(id: params[:id])
    return head :not_found unless vc

    render json: {
      id: vc.id,
      status: vc.status,
      transcript: vc.transcript,
      intent: vc.intent,
      result: vc.result,
      error: vc.error_message,
    }
  end

  def create
    smartmenu = find_smartmenu
    return head :not_found unless smartmenu

    vc = VoiceCommand.create!(
      smartmenu: smartmenu,
      session_id: session.id.to_s,
      status: :queued,
      locale: params[:locale].presence,
      transcript: params[:transcript].presence,
      context: {
        restaurant_id: params[:restaurant_id].presence,
        menu_id: params[:menu_id].presence,
        order_id: params[:order_id].presence,
      },
    )

    if params[:audio].present?
      vc.audio.attach(params[:audio])
    end

    VoiceCommandTranscriptionJob.perform_async(vc.id)

    render json: { id: vc.id, status: vc.status }, status: :accepted
  end

  private

  def ensure_voice_enabled
    return if ENV['SMART_MENU_VOICE_ENABLED'].to_s.downcase == 'true'

    head :not_found
  end

  def find_smartmenu
    Smartmenu.find_by(slug: params[:smartmenu_id]) ||
      (params[:smartmenu_id].to_s.match?(/\A\d+\z/) ? Smartmenu.find_by(id: params[:smartmenu_id]) : nil)
  end
end
