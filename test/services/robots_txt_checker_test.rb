require 'test_helper'

class RobotsTxtCheckerTest < ActiveSupport::TestCase
  def setup
    @checker = MenuDiscovery::RobotsTxtChecker.new
  end

  # Test the internal parse method

  test 'parse extracts disallow rules for wildcard agent' do
    robots = "User-agent: *\nDisallow: /"
    rules = @checker.send(:parse, robots)
    assert rules.key?('*')
    assert_includes rules['*'][:disallow], '/'
  end

  test 'parse extracts rules for SmartMenuBot agent' do
    robots = "User-agent: SmartMenuBot\nDisallow: /secret/"
    rules = @checker.send(:parse, robots)
    assert rules.key?('smartmenubot')
    assert_includes rules['smartmenubot'][:disallow], '/secret/'
  end

  test 'parse handles multiple agents' do
    robots = "User-agent: Googlebot\nDisallow: /private/\n\nUser-agent: *\nDisallow: /admin/"
    rules = @checker.send(:parse, robots)
    assert rules.key?('googlebot')
    assert_includes rules['googlebot'][:disallow], '/private/'
    assert rules.key?('*')
    assert_includes rules['*'][:disallow], '/admin/'
  end

  test 'parse extracts allow rules' do
    robots = "User-agent: *\nAllow: /menu\nDisallow: /"
    rules = @checker.send(:parse, robots)
    assert_includes rules['*'][:allow], '/menu'
    assert_includes rules['*'][:disallow], '/'
  end

  # Test check_rules with the {allow:[], disallow:[]} format

  test 'check_rules allows path not matching any disallow' do
    rules = { '*' => { allow: [], disallow: ['/private/', '/admin/'] } }
    assert @checker.send(:check_rules, rules, '/menu')
  end

  test 'check_rules blocks path matching disallow' do
    rules = { '*' => { allow: [], disallow: ['/private/', '/admin/'] } }
    assert_not @checker.send(:check_rules, rules, '/private/stuff')
  end

  test 'check_rules blocks all paths when root disallowed' do
    rules = { '*' => { allow: [], disallow: ['/'] } }
    assert_not @checker.send(:check_rules, rules, '/menu')
    assert_not @checker.send(:check_rules, rules, '/anything')
  end

  test 'check_rules uses SmartMenuBot-specific rules over wildcard' do
    rules = {
      '*' => { allow: [], disallow: [] },
      'smartmenubot' => { allow: [], disallow: ['/'] },
    }
    assert_not @checker.send(:check_rules, rules, '/menu')
  end

  test 'check_rules allows path when allow is longer than disallow' do
    rules = { '*' => { allow: ['/menu/public'], disallow: ['/menu'] } }
    assert @checker.send(:check_rules, rules, '/menu/public/today')
  end

  # Test allowed? with stubbed fetch_raw

  test 'allowed? returns true when robots.txt not found' do
    @checker.stub(:fetch_raw, nil) do
      assert @checker.allowed?('https://example.com/menu')
    end
  end

  test 'allowed? returns false when all bots disallowed' do
    @checker.stub(:fetch_raw, "User-agent: *\nDisallow: /") do
      assert_not @checker.allowed?('https://example.com/menu')
    end
  end

  test 'allowed? returns true when only other bots disallowed' do
    @checker.stub(:fetch_raw, "User-agent: Googlebot\nDisallow: /") do
      assert @checker.allowed?('https://example.com/menu')
    end
  end

  # Test evidence

  test 'evidence returns structured hash with robots_allowed false when blocked' do
    @checker.stub(:fetch_raw, "User-agent: *\nDisallow: /") do
      ev = @checker.evidence('https://example.com/menu')
      assert_instance_of Hash, ev
      assert_equal 'found', ev['robots_txt']
      assert_equal false, ev['robots_allowed']
      assert ev['robots_checked_at'].present?
    end
  end

  test 'evidence returns robots_allowed true when not blocked' do
    @checker.stub(:fetch_raw, "User-agent: Googlebot\nDisallow: /") do
      ev = @checker.evidence('https://example.com/menu')
      assert_equal true, ev['robots_allowed']
    end
  end

  test 'evidence returns not_found when robots.txt is absent' do
    @checker.stub(:fetch_raw, nil) do
      ev = @checker.evidence('https://example.com/menu')
      assert_equal 'not_found', ev['robots_txt']
    end
  end
end
