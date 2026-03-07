class OcrMenuImportBroadcastService
  class << self
    def broadcast_progress(ocr_menu_import)
      return if ocr_menu_import.blank?

      ActionCable.server.broadcast(
        "ocr_menu_import_#{ocr_menu_import.id}",
        {
          event: 'progress',
          import_id: ocr_menu_import.id,
          progress: ocr_menu_import.progress_payload,
          timestamp: Time.current.iso8601,
        },
      )
    end
  end
end
