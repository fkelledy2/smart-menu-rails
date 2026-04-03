# frozen_string_literal: true

require 'test_helper'

class Agents::Tools::ComposeRecommendationTest < ActiveSupport::TestCase
  def build_client_stub(return_value)
    stub = Minitest::Mock.new
    stub.expect(:chat_with_tools, return_value, [], model: String, messages: Array, tools: Array, temperature: Float)
    stub
  end

  test 'tool_name is compose_recommendation' do
    assert_equal 'compose_recommendation', Agents::Tools::ComposeRecommendation.tool_name
  end

  test 'description is present' do
    assert Agents::Tools::ComposeRecommendation.description.present?
  end

  test 'input_schema requires items and query' do
    schema = Agents::Tools::ComposeRecommendation.input_schema
    assert_includes schema[:required], 'items'
    assert_includes schema[:required], 'query'
  end

  test 'call returns parsed items array from valid LLM JSON' do
    llm_json = [{ 'id' => 1, 'name' => 'Pizza', 'price' => 12.5, 'explanation' => 'A classic.' }].to_json
    stub_response = { 'choices' => [{ 'message' => { 'content' => llm_json } }] }

    client_stub = build_client_stub(stub_response)
    OpenaiClient.stub(:new, client_stub) do
      result = Agents::Tools::ComposeRecommendation.call(
        'items' => [{ id: 1, name: 'Pizza', price: 12.5 }],
        'query' => 'Something Italian',
        'locale' => 'en',
      )
      assert_equal 1, result[:items].size
      assert_equal 1, result[:items].first['id']
      assert_equal 'A classic.', result[:items].first['explanation']
    end
  end

  test 'call filters out IDs not in provided item list' do
    # LLM returns an ID not in our item list — should be stripped
    llm_json = [
      { 'id' => 1, 'name' => 'Pizza', 'price' => 12.5, 'explanation' => 'Good.' },
      { 'id' => 999, 'name' => 'Invented', 'price' => 99.0, 'explanation' => 'Invented.' },
    ].to_json
    stub_response = { 'choices' => [{ 'message' => { 'content' => llm_json } }] }

    client_stub = build_client_stub(stub_response)
    OpenaiClient.stub(:new, client_stub) do
      result = Agents::Tools::ComposeRecommendation.call(
        'items' => [{ id: 1, name: 'Pizza', price: 12.5 }],
        'query' => 'anything',
      )
      assert_equal 1, result[:items].size
      assert_equal 1, result[:items].first['id']
    end
  end

  test 'call returns empty items on invalid JSON from LLM' do
    stub_response = { 'choices' => [{ 'message' => { 'content' => 'not json at all' } }] }

    client_stub = build_client_stub(stub_response)
    OpenaiClient.stub(:new, client_stub) do
      result = Agents::Tools::ComposeRecommendation.call(
        'items' => [{ id: 1, name: 'Pizza', price: 12.5 }],
        'query' => 'anything',
      )
      assert_equal [], result[:items]
    end
  end

  test 'call handles markdown-fenced JSON from LLM' do
    llm_json = "```json\n[{\"id\":1,\"name\":\"Pizza\",\"price\":12.5,\"explanation\":\"Tasty.\"}]\n```"
    stub_response = { 'choices' => [{ 'message' => { 'content' => llm_json } }] }

    client_stub = build_client_stub(stub_response)
    OpenaiClient.stub(:new, client_stub) do
      result = Agents::Tools::ComposeRecommendation.call(
        'items' => [{ id: 1, name: 'Pizza', price: 12.5 }],
        'query' => 'something tasty',
      )
      assert_equal 1, result[:items].size
    end
  end

  test 'call returns error hash when OpenAI client raises' do
    error_client = Object.new
    def error_client.chat_with_tools(**_kwargs)
      raise OpenaiClient::ApiError, 'API unavailable'
    end

    OpenaiClient.stub(:new, error_client) do
      result = Agents::Tools::ComposeRecommendation.call(
        'items' => [{ id: 1, name: 'Pizza', price: 12.5 }],
        'query' => 'anything',
      )
      assert result.key?(:error)
      assert_equal [], result[:items]
    end
  end

  test 'call limits recommendations to MAX_ITEMS' do
    many_items = (1..20).map { |i| { 'id' => i, 'name' => "Item #{i}", 'price' => 10.0, 'explanation' => 'Good.' } }
    (1..20).to_a
    llm_json = many_items.to_json
    stub_response = { 'choices' => [{ 'message' => { 'content' => llm_json } }] }

    source_items = (1..20).map { |i| { id: i, name: "Item #{i}", price: 10.0 } }

    client_stub = build_client_stub(stub_response)
    OpenaiClient.stub(:new, client_stub) do
      result = Agents::Tools::ComposeRecommendation.call(
        'items' => source_items,
        'query' => 'everything',
      )
      assert result[:items].size <= Agents::Tools::ComposeRecommendation::MAX_ITEMS
    end
  end
end
