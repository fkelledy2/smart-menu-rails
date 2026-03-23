# frozen_string_literal: true

require 'test_helper'

class SmartMenuMlClientTest < ActiveSupport::TestCase
  # =========================================================================
  # enabled?
  # =========================================================================

  test 'enabled? returns false when base_url is blank' do
    ENV.delete('SMART_MENU_ML_URL')
    client = SmartMenuMlClient.new(base_url: '')
    assert_equal false, client.enabled?
  end

  test 'enabled? returns false when SMART_MENU_ML_URL is not set' do
    ENV.delete('SMART_MENU_ML_URL')
    client = SmartMenuMlClient.new
    assert_equal false, client.enabled?
  end

  test 'enabled? returns true when base_url is present' do
    client = SmartMenuMlClient.new(base_url: 'http://ml.example.com')
    assert_equal true, client.enabled?
  end

  # =========================================================================
  # embed — guard path when disabled
  # =========================================================================

  test 'embed returns nil when base_url is blank' do
    client = SmartMenuMlClient.new(base_url: '')
    result = client.embed(texts: ['hello'])
    assert_nil result
  end

  test 'rerank returns nil when base_url is blank' do
    client = SmartMenuMlClient.new(base_url: '')
    result = client.rerank(query: 'burger', candidates: [])
    assert_nil result
  end

  # =========================================================================
  # embed — stubbed HTTP response
  # =========================================================================

  test 'embed returns vectors array from successful response' do
    fake_resp = Object.new
    fake_resp.define_singleton_method(:code) { 200 }
    fake_resp.define_singleton_method(:parsed_response) { { 'vectors' => [[0.1, 0.2, 0.3]] } }
    fake_resp.define_singleton_method(:body) { '{"vectors":[[0.1,0.2,0.3]]}' }

    client = SmartMenuMlClient.new(base_url: 'http://ml.example.com')
    SmartMenuMlClient.stub(:post, fake_resp) do
      result = client.embed(texts: ['burger'], locale: 'en')
      assert_equal [[0.1, 0.2, 0.3]], result
    end
  end

  test 'embed raises when HTTP response code is not 2xx' do
    fake_resp = Object.new
    fake_resp.define_singleton_method(:code) { 503 }
    fake_resp.define_singleton_method(:parsed_response) { {} }
    fake_resp.define_singleton_method(:body) { 'Service Unavailable' }

    client = SmartMenuMlClient.new(base_url: 'http://ml.example.com')
    SmartMenuMlClient.stub(:post, fake_resp) do
      assert_raises(RuntimeError, /embed failed/) do
        client.embed(texts: ['pizza'])
      end
    end
  end

  test 'embed raises when response does not contain vectors array' do
    fake_resp = Object.new
    fake_resp.define_singleton_method(:code) { 200 }
    fake_resp.define_singleton_method(:parsed_response) { { 'error' => 'unexpected' } }
    fake_resp.define_singleton_method(:body) { '{"error":"unexpected"}' }

    client = SmartMenuMlClient.new(base_url: 'http://ml.example.com')
    SmartMenuMlClient.stub(:post, fake_resp) do
      assert_raises(RuntimeError, /invalid response/) do
        client.embed(texts: ['test'])
      end
    end
  end

  # =========================================================================
  # rerank — stubbed HTTP response
  # =========================================================================

  test 'rerank returns ranked array from successful response' do
    ranked = [{ 'id' => '1', 'score' => 0.95 }]
    fake_resp = Object.new
    fake_resp.define_singleton_method(:code) { 200 }
    fake_resp.define_singleton_method(:parsed_response) { { 'ranked' => ranked } }
    fake_resp.define_singleton_method(:body) { '' }

    client = SmartMenuMlClient.new(base_url: 'http://ml.example.com')
    SmartMenuMlClient.stub(:post, fake_resp) do
      result = client.rerank(query: 'burger', candidates: [{ id: '1', text: 'Beef Burger' }])
      assert_equal ranked, result
    end
  end

  test 'rerank raises when response code is not 2xx' do
    fake_resp = Object.new
    fake_resp.define_singleton_method(:code) { 500 }
    fake_resp.define_singleton_method(:parsed_response) { {} }
    fake_resp.define_singleton_method(:body) { 'Internal Server Error' }

    client = SmartMenuMlClient.new(base_url: 'http://ml.example.com')
    SmartMenuMlClient.stub(:post, fake_resp) do
      assert_raises(RuntimeError, /rerank failed/) do
        client.rerank(query: 'test', candidates: [])
      end
    end
  end
end
