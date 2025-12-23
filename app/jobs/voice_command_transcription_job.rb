class VoiceCommandTranscriptionJob
  include Sidekiq::Job

  sidekiq_options queue: 'default', retry: 2

  def perform(voice_command_id)
    vc = VoiceCommand.find_by(id: voice_command_id)
    return unless vc

    vc.update!(status: :processing)

    transcript = vc.transcript.to_s

    if transcript.blank?
      if vc.audio.attached?
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
    end

    transcript = transcript.to_s.strip

    intent = VoiceCommandIntentService.new(transcript: transcript).parse

    vc.update!(
      status: :completed,
      transcript: transcript,
      intent: intent,
      result: { ok: true }
    )
  rescue StandardError => e
    begin
      vc.update!(status: :failed, error_message: "#{e.class}: #{e.message}") if vc
    rescue StandardError
      # ignore
    end
    raise
  end
end
