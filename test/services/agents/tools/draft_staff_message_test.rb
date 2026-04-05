# frozen_string_literal: true

require 'test_helper'

class Agents::Tools::DraftStaffMessageTest < ActiveSupport::TestCase
  test 'returns subject and body hash' do
    # Stub LLM to avoid real API call
    stub_openai_response('{"subject":"Team Update","body":"Great news from the team!"}') do
      result = Agents::Tools::DraftStaffMessage.call(
        'restaurant_name' => 'Test Restaurant',
        'topic'           => 'new seasonal menu',
      )
      assert_kind_of Hash, result
      assert result[:subject].present?
      assert result[:body].present?
    end
  end

  test 'returns fallback when LLM fails' do
    OpenaiClient.any_instance.stub(:chat_with_tools, ->(**_kwargs) { raise 'Network error' }) do
      result = Agents::Tools::DraftStaffMessage.call(
        'restaurant_name' => 'Test Restaurant',
        'topic'           => 'staff rota',
      )
      assert_equal 'Team Update', result[:subject]
      assert result[:body].present?
    end
  end

  test 'returns fallback on JSON parse error' do
    stub_openai_response('This is not JSON') do
      result = Agents::Tools::DraftStaffMessage.call(
        'restaurant_name' => 'Test Restaurant',
        'topic'           => 'shift briefing',
      )
      assert_equal 'Team Update', result[:subject]
      assert result[:body].present?
    end
  end

  private

  def stub_openai_response(content)
    response_data = { 'choices' => [{ 'message' => { 'content' => content } }] }
    OpenaiClient.any_instance.stub(:chat_with_tools, ->(**_kwargs) { response_data }) do
      yield
    end
  end
end
