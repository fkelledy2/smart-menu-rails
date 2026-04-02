# frozen_string_literal: true

require 'test_helper'

class Agents::Workflows::MenuImportWorkflowTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @ocr_import = ocr_menu_imports(:completed_import)
    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'menu_import',
      trigger_event: 'menu.import.requested',
      status: 'pending',
      context_snapshot: {
        'restaurant_id' => @restaurant.id,
        'ocr_menu_import_id' => @ocr_import.id,
      },
    )
    @workflow = Agents::Workflows::MenuImportWorkflow.new(@run)
  end

  # ---------------------------------------------------------------------------
  # Step provisioning
  # ---------------------------------------------------------------------------

  test 'provision_steps! creates all 8 steps' do
    assert_difference 'AgentWorkflowStep.count', 8 do
      @workflow.send(:provision_steps!)
    end
  end

  test 'provision_steps! does not duplicate steps on second call' do
    @workflow.send(:provision_steps!)
    assert_no_difference 'AgentWorkflowStep.count' do
      @workflow.send(:provision_steps!)
    end
  end

  test 'step names match STEP_NAMES constant' do
    @workflow.send(:provision_steps!)
    step_names = @run.agent_workflow_steps.order(:step_index).pluck(:step_name)
    assert_equal Agents::Workflows::MenuImportWorkflow::STEP_NAMES, step_names
  end

  test 'step indexes are sequential starting at 0' do
    @workflow.send(:provision_steps!)
    indexes = @run.agent_workflow_steps.order(:step_index).pluck(:step_index)
    assert_equal (0..7).to_a, indexes
  end

  # ---------------------------------------------------------------------------
  # Step 1: fetch_source
  # ---------------------------------------------------------------------------

  test 'step_fetch_source returns expected keys' do
    result = @workflow.send(:step_fetch_source)
    assert result.key?(:ocr_menu_import_id)
    assert result.key?(:raw_text)
    assert result.key?(:sections_count)
    assert result.key?(:items_count)
  end

  test 'step_fetch_source updates import agent_status to processing' do
    @workflow.send(:step_fetch_source)
    assert_equal 'processing', @ocr_import.reload.agent_status
  end

  # ---------------------------------------------------------------------------
  # Step 2: read_context
  # ---------------------------------------------------------------------------

  test 'step_read_context returns restaurant information' do
    result = @workflow.send(:step_read_context)
    assert_equal @restaurant.id, result[:restaurant_id]
    assert result.key?(:currency)
    assert result.key?(:existing_menus)
  end

  # ---------------------------------------------------------------------------
  # Step 5: policy_validate
  # ---------------------------------------------------------------------------

  test 'step_policy_validate marks allergen items as require_approval' do
    # bruschetta has allergens: ["gluten"], ensure confidence is high
    item = ocr_menu_items(:bruschetta)
    item.update_columns(confidence_score: 0.95)

    @workflow.send(:step_policy_validate)
    assert_equal 'require_approval', item.reload.agent_approval_status
  end

  test 'step_policy_validate marks high-confidence allergen-free items as auto_approved' do
    # Create an item with no allergens and high confidence
    section = ocr_menu_sections(:starters_section)
    item = section.ocr_menu_items.create!(
      name: 'Test Clean Item',
      sequence: 99,
      allergens: [],
      confidence_score: 0.92,
    )

    @workflow.send(:step_policy_validate)
    assert_equal 'auto_approved', item.reload.agent_approval_status
  end

  test 'step_policy_validate marks low-confidence items as require_approval' do
    section = ocr_menu_sections(:starters_section)
    item = section.ocr_menu_items.create!(
      name: 'Low Confidence Item',
      sequence: 100,
      allergens: [],
      confidence_score: 0.5,
    )

    @workflow.send(:step_policy_validate)
    assert_equal 'require_approval', item.reload.agent_approval_status
  end

  # ---------------------------------------------------------------------------
  # Step 6: write_draft
  # ---------------------------------------------------------------------------

  test 'step_write_draft creates an AgentArtifact with menu_import_draft type' do
    # Simulate prior steps being completed
    @workflow.send(:provision_steps!)
    @run.agent_workflow_steps.find_by(step_name: 'normalise_and_tag').update!(
      status: 'completed',
      output_snapshot: { 'normalised_sections' => [] },
    )
    @run.agent_workflow_steps.find_by(step_name: 'policy_validate').update!(
      status: 'completed',
      output_snapshot: { 'auto_approved_count' => 3, 'require_approval_count' => 1 },
    )

    assert_difference 'AgentArtifact.count', 1 do
      @workflow.send(:step_write_draft)
    end

    artifact = AgentArtifact.last
    assert_equal 'menu_import_draft', artifact.artifact_type
    assert_equal 'draft', artifact.status
    assert_equal @run, artifact.agent_workflow_run
  end

  test 'step_write_draft links import to workflow run' do
    @workflow.send(:provision_steps!)
    @run.agent_workflow_steps.find_by(step_name: 'normalise_and_tag').update!(
      status: 'completed',
      output_snapshot: { 'normalised_sections' => [] },
    )
    @run.agent_workflow_steps.find_by(step_name: 'policy_validate').update!(
      status: 'completed',
      output_snapshot: { 'auto_approved_count' => 0, 'require_approval_count' => 0 },
    )

    @workflow.send(:step_write_draft)
    assert_equal @run.id, @ocr_import.reload.agent_workflow_run_id
  end

  # ---------------------------------------------------------------------------
  # JSON parsing helper
  # ---------------------------------------------------------------------------

  test 'parse_json_from_llm handles clean JSON' do
    json = '{"sections": [{"name": "Starters", "items": []}]}'
    result = @workflow.send(:parse_json_from_llm, json)
    assert_equal 'Starters', result['sections'][0]['name']
  end

  test 'parse_json_from_llm strips markdown fences' do
    json = "```json\n{\"sections\": []}\n```"
    result = @workflow.send(:parse_json_from_llm, json)
    assert_equal [], result['sections']
  end

  test 'parse_json_from_llm extracts JSON from surrounding prose' do
    json = "Here is the response:\n{\"sections\": []}\nThat's all."
    result = @workflow.send(:parse_json_from_llm, json)
    assert_equal [], result['sections']
  end

  # ---------------------------------------------------------------------------
  # Error handling
  # ---------------------------------------------------------------------------

  test 'handles missing ocr_import gracefully with failed run' do
    run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'menu_import',
      trigger_event: 'menu.import.requested',
      status: 'pending',
      context_snapshot: { 'restaurant_id' => @restaurant.id, 'ocr_menu_import_id' => 999_999 },
    )
    workflow = Agents::Workflows::MenuImportWorkflow.new(run)
    # Should not raise, should fail gracefully
    workflow.call
    assert run.reload.failed?
  end
end
