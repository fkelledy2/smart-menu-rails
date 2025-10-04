class ProcessPdfJob < ApplicationJob
  queue_as :default
  
  # Retry configuration to prevent infinite retries
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(ocr_menu_import_id)
    # Use find_by to avoid RecordNotFound exception
    ocr_menu_import = OcrMenuImport.find_by(id: ocr_menu_import_id)
    
    # If record doesn't exist, log and exit gracefully (don't retry)
    unless ocr_menu_import
      Rails.logger.warn "ProcessPdfJob: OcrMenuImport with ID #{ocr_menu_import_id} not found. Record may have been deleted."
      return
    end

    begin
      # Start processing only if allowed
      if ocr_menu_import.may_process?
        ocr_menu_import.process!
      elsif ocr_menu_import.failed? || ocr_menu_import.completed?
        Rails.logger.info "ProcessPdfJob: Skipping processing for OcrMenuImport ##{ocr_menu_import.id} in state '#{ocr_menu_import.status}'"
        return
      end

      # Process the PDF using our service
      processor = PdfMenuProcessor.new(ocr_menu_import)
      success = processor.process

      raise PdfMenuProcessor::ProcessingError, 'Failed to process PDF' unless success

      # Complete only if in processing state
      if ocr_menu_import.respond_to?(:may_complete?) && ocr_menu_import.may_complete?
        ocr_menu_import.complete!
      else
        Rails.logger.warn "ProcessPdfJob: Cannot complete OcrMenuImport ##{ocr_menu_import.id} from state '#{ocr_menu_import.status}'"
      end
    rescue StandardError => e
      Rails.logger.error "Error in ProcessPdfJob: #{e.message}\n#{e.backtrace.join("\n")}"
      
      # Handle case where record might have been deleted during processing
      unless ocr_menu_import.persisted?
        Rails.logger.warn "ProcessPdfJob: OcrMenuImport ##{ocr_menu_import_id} was deleted during processing"
        return
      end
      
      # Fail only if allowed; otherwise, just record the error
      if ocr_menu_import.respond_to?(:may_fail?) && ocr_menu_import.may_fail?
        begin
          ocr_menu_import.fail!(e.message)
        rescue AASM::InvalidTransition
          ocr_menu_import.update(error_message: e.message, failed_at: Time.current)
        rescue ActiveRecord::RecordNotFound
          Rails.logger.warn "ProcessPdfJob: OcrMenuImport ##{ocr_menu_import_id} was deleted while updating error state"
          return
        end
      else
        # Already in failed/completed state; update error details but avoid infinite retry loop
        begin
          ocr_menu_import.update(error_message: e.message, failed_at: ocr_menu_import.failed_at || Time.current)
        rescue ActiveRecord::RecordNotFound
          Rails.logger.warn "ProcessPdfJob: OcrMenuImport ##{ocr_menu_import_id} was deleted while updating error details"
          return
        end
        # Only re-raise for non-AASM errors to allow genuine retries
        raise e unless e.is_a?(AASM::InvalidTransition)
      end
    end
  end
end
