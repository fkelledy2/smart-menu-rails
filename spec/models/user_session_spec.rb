require 'rails_helper'

RSpec.describe UserSession, type: :model do
  let(:user) { create(:user) }

  it 'validates session_id and allowed status values' do
    record = described_class.new(user: user, resource_type: 'Menu', resource_id: 1)

    expect(record).not_to be_valid
    expect(record.errors[:session_id]).to be_present

    record.status = 'not-a-real-status'
    expect(record).not_to be_valid
    expect(record.errors[:status]).to be_present
  end

  it 'touches activity and marks the session active' do
    session = create(:user_session, user: user, session_id: SecureRandom.uuid, status: 'idle', resource_type: 'Menu', resource_id: 1, last_activity_at: 10.minutes.ago)
    now = Time.zone.parse('2026-03-08 10:45:00 UTC')

    allow(Time).to receive(:current).and_return(now)
    allow(Time.zone).to receive(:now).and_return(now)

    session.touch_activity!
    session.reload

    expect(session.status).to eq('active')
    expect(session.last_activity_at.to_i).to eq(now.to_i)
  end

  it 'reports stale sessions correctly' do
    fresh = create(:user_session, user: user, session_id: SecureRandom.uuid, status: 'active', resource_type: 'Menu', resource_id: 1, last_activity_at: 2.minutes.ago)
    stale = create(:user_session, user: user, session_id: SecureRandom.uuid, status: 'active', resource_type: 'Menu', resource_id: 1, last_activity_at: 10.minutes.ago)

    expect(fresh).not_to be_stale
    expect(stale).to be_stale
    expect(described_class.stale).to include(stale)
    expect(described_class.stale).not_to include(fresh)
  end
end
