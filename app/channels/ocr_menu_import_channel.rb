class OcrMenuImportChannel < ApplicationCable::Channel
  def subscribed
    restaurant_id = params[:restaurant_id]
    import_id = params[:import_id]
    return reject unless restaurant_id.present? && import_id.present?

    import = OcrMenuImport.find_by(id: import_id, restaurant_id: restaurant_id)
    return reject unless import

    return reject unless current_user && import.restaurant&.user_id == current_user.id

    stream_from "ocr_menu_import_#{import.id}"
    transmit(
      event: 'progress',
      import_id: import.id,
      progress: import.progress_payload,
      timestamp: Time.current.iso8601,
    )
  end

  def unsubscribed
  end
end
