class SmartmenusVoiceCommandsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def create
    smartmenu = Smartmenu.find_by(slug: params[:smartmenu_id]) || Smartmenu.find(params[:smartmenu_id])

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
      }
    )

    if params[:audio].present?
      vc.audio.attach(params[:audio])
    end

    VoiceCommandTranscriptionJob.perform_async(vc.id)

    render json: { id: vc.id, status: vc.status }, status: :accepted
  end

  def show
    smartmenu = Smartmenu.find_by(slug: params[:smartmenu_id]) || Smartmenu.find(params[:smartmenu_id])
    vc = VoiceCommand.where(smartmenu: smartmenu, session_id: session.id.to_s).find(params[:id])

    render json: {
      id: vc.id,
      status: vc.status,
      transcript: vc.transcript,
      intent: vc.intent,
      result: vc.result,
      error: vc.error_message,
    }
  end
end
