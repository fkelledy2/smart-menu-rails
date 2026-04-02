# frozen_string_literal: true

require 'test_helper'

class Agents::ArtifactWriterTest < ActiveSupport::TestCase
  def setup
    @run = agent_workflow_runs(:completed_run)
  end

  test 'creates a draft artifact on success' do
    assert_difference 'AgentArtifact.count', 1 do
      result = Agents::ArtifactWriter.call(
        workflow_run: @run,
        artifact_type: 'menu_patch',
        content: { 'changes' => [] },
      )
      assert result.success?
      assert_not_nil result.artifact
      assert_equal 'draft', result.artifact.status
      assert_equal 'menu_patch', result.artifact.artifact_type
    end
  end

  test 'associates artifact with the workflow run' do
    result = Agents::ArtifactWriter.call(
      workflow_run: @run,
      artifact_type: 'summary',
      content: { 'text' => 'All good.' },
    )
    assert_equal @run, result.artifact.agent_workflow_run
  end

  test 'returns failure result on invalid artifact_type' do
    result = Agents::ArtifactWriter.call(
      workflow_run: @run,
      artifact_type: '', # blank triggers validation error
      content: {},
    )
    assert_not result.success?
    assert_not_nil result.error
  end
end
