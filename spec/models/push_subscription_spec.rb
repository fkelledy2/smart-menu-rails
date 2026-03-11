require 'rails_helper'

RSpec.describe PushSubscription do
  let(:user) { create(:user) }

  it 'validates required fields' do
    record = described_class.new(user: user)

    expect(record).not_to be_valid
    expect(record.errors[:endpoint]).to be_present
    expect(record.errors[:p256dh_key]).to be_present
    expect(record.errors[:auth_key]).to be_present
  end

  it 'enqueues a push notification for active subscriptions with stringified data keys' do
    subscription = create(:push_subscription, user: user, endpoint: 'https://push.example.test/1', p256dh_key: 'key', auth_key: 'auth', active: true)

    allow(PushNotificationJob).to receive(:perform_async)

    subscription.send_notification('Title', 'Body', { nested: 'value' })

    expect(PushNotificationJob).to have_received(:perform_async).with(
      subscription.id,
      hash_including(
        'title' => 'Title',
        'body' => 'Body',
        'data' => { 'nested' => 'value' },
      ),
    )
  end
end
