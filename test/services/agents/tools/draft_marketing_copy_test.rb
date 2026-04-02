# frozen_string_literal: true

require 'test_helper'

class Agents::Tools::DraftMarketingCopyTest < ActiveSupport::TestCase
  test 'tool_name is draft_marketing_copy' do
    assert_equal 'draft_marketing_copy', Agents::Tools::DraftMarketingCopy.tool_name
  end

  test 'description is present' do
    assert Agents::Tools::DraftMarketingCopy.description.present?
  end

  test 'input_schema has required fields' do
    schema = Agents::Tools::DraftMarketingCopy.input_schema
    assert_equal 'object', schema[:type]
    assert_includes schema[:required], 'item_name'
    assert_includes schema[:required], 'restaurant_name'
  end

  test 'call returns instagram_caption and email_body keys' do
    stub_response = {
      'choices' => [{
        'message' => {
          'content' => '{"instagram_caption":"Great pasta!","email_body":"Join us for pasta night."}',
        },
      }],
    }

    client_stub = build_client_stub(stub_response)
    OpenaiClient.stub(:new, client_stub) do
      result = Agents::Tools::DraftMarketingCopy.call(
        'item_name' => 'Spaghetti Carbonara',
        'restaurant_name' => 'Test Restaurant',
      )
      assert result.key?(:instagram_caption)
      assert result.key?(:email_body)
      assert_equal 'Great pasta!', result[:instagram_caption]
    end
  end

  test 'call accepts symbol keys' do
    stub_response = {
      'choices' => [{
        'message' => {
          'content' => '{"instagram_caption":"Try this!","email_body":"Weekend special."}',
        },
      }],
    }

    client_stub = build_client_stub(stub_response)
    OpenaiClient.stub(:new, client_stub) do
      result = Agents::Tools::DraftMarketingCopy.call(
        item_name: 'Burger',
        restaurant_name: 'Burger Place',
      )
      assert_equal 'Try this!', result[:instagram_caption]
    end
  end

  test 'call returns empty strings when OpenAI raises' do
    error_client = build_error_client
    OpenaiClient.stub(:new, error_client) do
      result = Agents::Tools::DraftMarketingCopy.call(
        'item_name' => 'Pasta',
        'restaurant_name' => 'Restaurant',
      )
      assert_equal '', result[:instagram_caption]
      assert_equal '', result[:email_body]
    end
  end

  test 'call strips markdown fences from LLM response' do
    stub_response = {
      'choices' => [{
        'message' => {
          'content' => "```json\n{\"instagram_caption\":\"Hello!\",\"email_body\":\"Visit us.\"}\n```",
        },
      }],
    }

    client_stub = build_client_stub(stub_response)
    OpenaiClient.stub(:new, client_stub) do
      result = Agents::Tools::DraftMarketingCopy.call(
        'item_name' => 'Pizza',
        'restaurant_name' => 'Pizzeria',
      )
      assert_equal 'Hello!', result[:instagram_caption]
    end
  end

  private

  def build_client_stub(response)
    Object.new.tap do |obj|
      obj.define_singleton_method(:chat_with_tools) { |**_| response }
    end
  end

  def build_error_client
    Object.new.tap do |obj|
      obj.define_singleton_method(:chat_with_tools) { |**_| raise 'API error' }
    end
  end
end
