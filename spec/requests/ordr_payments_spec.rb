require 'rails_helper'

RSpec.describe 'OrdrPayments' do
  let(:restaurant) { create(:restaurant, currency: 'USD') }
  let(:menu) { create(:menu, restaurant: restaurant) }
  let(:tablesetting) { create(:tablesetting, restaurant: restaurant) }
  let(:ordr) { create(:ordr, restaurant: restaurant, menu: menu, tablesetting: tablesetting, gross: 10.0, status: :opened) }

  around do |example|
    prev = Stripe.api_key
    Stripe.api_key = 'sk_test_spec'
    example.run
  ensure
    Stripe.api_key = prev
  end

  describe 'POST /restaurants/:restaurant_id/ordrs/:id/request_bill' do
    it 'returns 422 when there are opened items' do
      create(:ordritem, ordr: ordr, status: :opened)

      post "/restaurants/#{restaurant.id}/ordrs/#{ordr.id}/request_bill", headers: { 'ACCEPT' => 'application/json' }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(ordr.reload.status).not_to eq('billrequested')
    end

    it 'transitions to billrequested when eligible' do
      create(:ordritem, ordr: ordr, status: :ordered)

      post "/restaurants/#{restaurant.id}/ordrs/#{ordr.id}/request_bill", headers: { 'ACCEPT' => 'application/json' }, as: :json

      expect(response).to have_http_status(:ok)
      expect(ordr.reload.status).to eq('billrequested')
    end
  end

  describe 'POST /restaurants/:restaurant_id/ordrs/:id/split_evenly' do
    it 'creates per-participant split payments with even-split rounding' do
      ordr.update!(status: :billrequested)
      create(:ordrparticipant, ordr: ordr, role: :customer, sessionid: 'a')
      create(:ordrparticipant, ordr: ordr, role: :customer, sessionid: 'b')

      post "/restaurants/#{restaurant.id}/ordrs/#{ordr.id}/split_evenly", headers: { 'ACCEPT' => 'application/json' }, as: :json

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data['ok']).to eq(true)
      expect(data['split_payments'].length).to eq(2)

      amounts = data['split_payments'].map { |sp| sp['amount_cents'] }
      expect(amounts.sum).to eq(1000)
      expect(amounts.uniq).to eq([500])

      expect(ordr.ordr_split_payments.count).to eq(2)
    end
  end

  describe 'POST /restaurants/:restaurant_id/ordrs/:id/payments/checkout_session' do
    it 'returns checkout_url and persists Stripe IDs for split payments' do
      ordr.update!(status: :billrequested)
      p1 = create(:ordrparticipant, ordr: ordr, role: :customer, sessionid: 'a')
      sp = ordr.ordr_split_payments.create!(
        ordrparticipant: p1,
        amount_cents: 500,
        currency: 'USD',
        status: :requires_payment,
      )

      fake_session = Struct.new(:id, :url, :payment_intent).new('cs_test_123', 'https://stripe.test/checkout', 'pi_test_123')
      allow(Stripe::Checkout::Session).to receive(:create).and_return(fake_session)

      post "/restaurants/#{restaurant.id}/ordrs/#{ordr.id}/payments/checkout_session",
           params: { ordr_split_payment_id: sp.id, success_url: 'https://example.test/success', cancel_url: 'https://example.test/cancel' },
           headers: { 'ACCEPT' => 'application/json' },
           as: :json

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data['ok']).to eq(true)
      expect(data['checkout_url']).to eq('https://stripe.test/checkout')

      sp.reload
      expect(sp.status).to eq('pending')
      expect(sp.stripe_checkout_session_id).to eq('cs_test_123')
      expect(sp.stripe_payment_intent_id).to eq('pi_test_123')
    end
  end
end
