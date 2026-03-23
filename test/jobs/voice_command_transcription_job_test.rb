# frozen_string_literal: true

require 'test_helper'

class VoiceCommandTranscriptionJobTest < ActiveSupport::TestCase
  def setup
    @job = VoiceCommandTranscriptionJob.new
    @vc = VoiceCommand.create!(
      smartmenu: smartmenus(:one),
      session_id: "test-sess-#{SecureRandom.hex(8)}",
      status: :queued,
      transcript: 'add burger',
      locale: 'en',
    )
  end

  test 'does nothing when voice_command does not exist' do
    assert_nothing_raised do
      @job.perform(-999_999)
    end
  end

  test 'marks command as failed when voice is disabled' do
    ENV['SMART_MENU_VOICE_ENABLED'] = 'false'
    @job.perform(@vc.id)
    @vc.reload
    assert @vc.failed?
  ensure
    ENV.delete('SMART_MENU_VOICE_ENABLED')
  end

  test 'processes command with transcript when voice enabled' do
    ENV['SMART_MENU_VOICE_ENABLED'] = 'true'
    @job.perform(@vc.id)
    @vc.reload
    assert @vc.completed?
  ensure
    ENV.delete('SMART_MENU_VOICE_ENABLED')
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      VoiceCommandTranscriptionJob.perform_async(@vc.id)
    end
  end
end
