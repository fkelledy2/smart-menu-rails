# frozen_string_literal: true

require 'test_helper'

class SitemapGeneratorJobTest < ActiveSupport::TestCase
  test 'perform calls SitemapGenerator::Interpreter.run and pings search engines' do
    interpreter_called = false
    ping_called = false

    SitemapGenerator::Interpreter.stub(:run, -> { interpreter_called = true }) do
      SitemapGenerator::Sitemap.stub(:ping_search_engines, -> { ping_called = true }) do
        SitemapGeneratorJob.new.perform
      end
    end

    assert interpreter_called, 'Expected SitemapGenerator::Interpreter.run to be called'
    assert ping_called, 'Expected SitemapGenerator::Sitemap.ping_search_engines to be called'
  end

  test 'job is enqueued on the low queue' do
    assert_equal 'low', SitemapGeneratorJob.new.queue_name
  end
end
