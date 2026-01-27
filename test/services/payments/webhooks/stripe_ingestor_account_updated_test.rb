require 'test_helper'

class Payments::Webhooks::StripeIngestorAccountUpdatedTest < ActiveSupport::TestCase
  test 'account.updated upserts provider account from metadata restaurant_id' do
    restaurant = restaurants(:one)

    payload = {
      'data' => {
        'object' => {
          'id' => 'acct_123',
          'type' => 'express',
          'country' => 'US',
          'default_currency' => 'usd',
          'charges_enabled' => true,
          'payouts_enabled' => true,
          'details_submitted' => true,
          'capabilities' => { 'card_payments' => 'active' },
          'metadata' => { 'restaurant_id' => restaurant.id },
        },
      },
    }

    Payments::Webhooks::StripeIngestor.new.ingest!(
      provider_event_id: 'evt_acct_1',
      provider_event_type: 'account.updated',
      occurred_at: Time.current,
      payload: payload,
    )

    acct = ProviderAccount.find_by(provider: :stripe, provider_account_id: 'acct_123')
    assert acct
    assert_equal restaurant.id, acct.restaurant_id
    assert_equal 'enabled', acct.status.to_s
    assert_equal true, acct.payouts_enabled
  end
end
