require 'test_helper'

class Menu::GeneratePairingsJobTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @run = BeveragePipelineRun.create!(
      menu: @menu,
      restaurant: @restaurant,
      status: 'running',
      current_step: 'enrich_products',
      started_at: Time.current,
    )
  end

  test 'updates current_step to generate_pairings' do
    # Stub the next job in chain
    Menu::GenerateRecsJob.stub(:perform_async, nil) do
      Menu::GeneratePairingsJob.new.perform(@run.id, 'test')
    end
    @run.reload
    assert_equal 'generate_pairings', @run.current_step
  end

  test 'chains to GenerateRecsJob on success' do
    called_with = nil
    Menu::GenerateRecsJob.stub(:perform_async, ->(run_id, trigger) { called_with = [run_id, trigger] }) do
      Menu::GeneratePairingsJob.new.perform(@run.id, 'test')
    end
    assert_equal [@run.id, 'test'], called_with
  end

  test 'returns early for non-existent run without error' do
    assert_nothing_raised do
      Menu::GeneratePairingsJob.new.perform(999_999_999, 'test')
    end
  end

  test 'returns early for non-existent run' do
    assert_nothing_raised do
      Menu::GeneratePairingsJob.new.perform(-1, 'test')
    end
  end
end
