# frozen_string_literal: true

require 'test_helper'
require 'fileutils'
require 'stringio'

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

  test 'interpreter run writes sitemap artifact' do
    output_dir = Rails.root.join('tmp', 'sitemaps_test')
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)

    original_public_path = SitemapGenerator::Sitemap.public_path
    original_sitemaps_path = SitemapGenerator::Sitemap.sitemaps_path

    SitemapGenerator::Sitemap.public_path = output_dir.to_s
    SitemapGenerator::Sitemap.sitemaps_path = 'generated'

    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    SitemapGenerator::Interpreter.run

    generated_files = Dir.glob(output_dir.join('**', '*').to_s)
    assert generated_files.any? { |path| File.basename(path).match?(/sitemap.*\.xml(\.gz)?\z/) },
           'Expected sitemap generator to create a sitemap XML artifact'
  ensure
    $stdout = original_stdout if defined?(original_stdout) && original_stdout
    $stderr = original_stderr if defined?(original_stderr) && original_stderr
    SitemapGenerator::Sitemap.public_path = original_public_path
    SitemapGenerator::Sitemap.sitemaps_path = original_sitemaps_path
    FileUtils.rm_rf(output_dir) if output_dir
  end
end
