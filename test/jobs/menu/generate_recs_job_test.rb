require 'test_helper'

class Menu::GenerateRecsJobTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @run = BeveragePipelineRun.create!(
      menu: @menu,
      restaurant: @restaurant,
      status: 'running',
      current_step: 'generate_pairings',
      started_at: Time.current,
    )
  end

  test 'updates current_step to generate_recs' do
    Menu::PublishSommelierJob.stub(:perform_async, nil) do
      Menu::GenerateRecsJob.new.perform(@run.id, 'test')
    end
    @run.reload
    assert_equal 'generate_recs', @run.current_step
  end

  test 'chains to PublishSommelierJob on success' do
    called_with = nil
    Menu::PublishSommelierJob.stub(:perform_async, ->(run_id, trigger) { called_with = [run_id, trigger] }) do
      Menu::GenerateRecsJob.new.perform(@run.id, 'test')
    end
    assert_equal [@run.id, 'test'], called_with
  end

  test 'returns early for non-existent run without error' do
    assert_nothing_raised do
      Menu::GenerateRecsJob.new.perform(999_999_999, 'test')
    end
  end
end
