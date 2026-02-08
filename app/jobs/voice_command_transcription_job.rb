class VoiceCommandTranscriptionJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 2

  def perform(voice_command_id)
    vc = VoiceCommand.find_by(id: voice_command_id)
    return unless vc

    unless voice_enabled?
      vc.update!(status: :failed, error_message: 'Voice is disabled')
      return
    end

    vc.update!(status: :processing)

    transcript = vc.transcript.to_s

    if transcript.blank? && vc.audio.attached?
      unless whisper_enabled?
        vc.update!(status: :failed, error_message: 'Audio transcription is disabled')
        return
      end

      tmp = Tempfile.new(['voice_command', vc.audio.filename.extension_with_delimiter])
      begin
        tmp.binmode
        tmp.write(vc.audio.download)
        tmp.flush
        svc = OpenaiWhisperTranscriptionService.new
        transcript = svc.transcribe(file_path: tmp.path, language: vc.locale)
      ensure
        tmp.close
        tmp.unlink
      end
    end

    transcript = transcript.to_s.strip

    intent = VoiceCommandIntentService.new(transcript: transcript, locale: vc.locale).parse

    translated_transcript = nil
    if intent.is_a?(Hash) && intent[:type] == 'unknown'
      begin
        translated_transcript = translate_to_english_if_needed(transcript, vc.locale)
        if translated_transcript.present? && translated_transcript != transcript
          intent = VoiceCommandIntentService.new(transcript: translated_transcript, locale: 'en').parse
        end
      rescue StandardError
        translated_transcript = nil
      end
    end

    intent = enrich_item_intent(vc, intent)

    vc.update!(
      status: :completed,
      transcript: transcript,
      intent: intent,
      result: {
        ok: true,
        translated_transcript: translated_transcript.present? && translated_transcript != transcript ? translated_transcript : nil,
      },
    )
  rescue StandardError => e
    begin
      vc&.update!(status: :failed, error_message: "#{e.class}: #{e.message}")
    rescue StandardError
      # ignore
    end
    nil
  end

  private

  def voice_enabled?
    ENV['SMART_MENU_VOICE_ENABLED'].to_s.downcase == 'true'
  end

  def whisper_enabled?
    v = ENV.fetch('SMART_MENU_VOICE_WHISPER_ENABLED', nil)
    return true if v.nil? || v.to_s.strip == ''

    v.to_s.downcase == 'true'
  end

  def vector_search_enabled?
    v = ENV.fetch('SMART_MENU_VECTOR_SEARCH_ENABLED', nil)
    return true if v.nil? || v.to_s.strip == ''

    v.to_s.downcase == 'true'
  end

  def deepl_enabled?
    v = ENV.fetch('SMART_MENU_DEEPL_ENABLED', nil)
    return true if v.nil? || v.to_s.strip == ''

    v.to_s.downcase == 'true'
  end

  def translate_to_english_if_needed(transcript, locale)
    text = transcript.to_s.strip
    return text if text.blank?

    return text unless deepl_enabled?

    src = locale.to_s.strip
    src = src.split(/[-_]/).first.to_s.upcase
    return text if src.blank? || src == 'EN'

    # DeepL expects language codes like EN/FR/IT/ES/DE.
    DeeplApiService.translate(text, to: 'EN', from: src)
  rescue StandardError
    text
  end

  def enrich_item_intent(vc, intent)
    return intent unless intent.is_a?(Hash)

    type = intent[:type].to_s
    return intent unless %w[add_item remove_item].include?(type)

    return intent unless vector_search_enabled?

    ctx = vc.context.is_a?(Hash) ? vc.context : {}
    menu_id = ctx['menu_id'].presence
    return intent if menu_id.blank?

    q = intent[:query].to_s.strip
    q = vc.transcript.to_s.strip if q.blank?
    return intent if q.blank?

    match = MenuItemMatcherService.new(menu_id: menu_id.to_i, locale: vc.locale).match(q)
    return intent unless match.is_a?(Hash) && match[:menuitem_id].present?

    intent.merge(
      menuitem_id: match[:menuitem_id],
      confidence: match[:confidence],
      match_method: match[:method],
    )
  rescue StandardError
    intent
  end
end
