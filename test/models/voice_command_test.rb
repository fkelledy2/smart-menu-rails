# frozen_string_literal: true

require 'test_helper'

class VoiceCommandTest < ActiveSupport::TestCase
  def build_voice_command(overrides = {})
    VoiceCommand.new({
      smartmenu: smartmenus(:one),
      session_id: "sess-#{SecureRandom.hex(8)}",
      status: :queued,
    }.merge(overrides))
  end

  # =========================================================================
  # validations
  # =========================================================================

  test 'is valid with required attributes' do
    assert build_voice_command.valid?
  end

  test 'is invalid without session_id' do
    vc = build_voice_command(session_id: nil)
    assert_not vc.valid?
    assert vc.errors[:session_id].any?
  end

  test 'is invalid with blank session_id' do
    vc = build_voice_command(session_id: '')
    assert_not vc.valid?
    assert vc.errors[:session_id].any?
  end

  test 'is invalid without smartmenu' do
    vc = build_voice_command(smartmenu: nil)
    assert_not vc.valid?
  end

  # =========================================================================
  # enum
  # =========================================================================

  test 'status enum has queued processing completed and failed' do
    %w[queued processing completed failed].each do |status|
      vc = build_voice_command(status: status)
      assert_equal status, vc.status
    end
  end

  test 'queued? predicate works' do
    vc = build_voice_command(status: 'queued')
    assert vc.queued?
  end

  test 'completed? predicate works' do
    vc = build_voice_command(status: 'completed')
    assert vc.completed?
  end

  test 'failed? predicate works' do
    vc = build_voice_command(status: 'failed')
    assert vc.failed?
  end

  # =========================================================================
  # associations
  # =========================================================================

  test 'belongs to smartmenu' do
    vc = build_voice_command
    assert_equal smartmenus(:one), vc.smartmenu
  end
end
