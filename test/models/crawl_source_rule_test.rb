require 'test_helper'

class CrawlSourceRuleTest < ActiveSupport::TestCase
  test 'valid rule saves' do
    rule = CrawlSourceRule.new(domain: 'deliveroo.ie', rule_type: :blacklist, reason: 'Delivery platform')
    assert rule.valid?, rule.errors.full_messages.join(', ')
    assert rule.save
  end

  test 'requires domain' do
    rule = CrawlSourceRule.new(rule_type: :blacklist)
    assert_not rule.valid?
    assert_includes rule.errors[:domain], "can't be blank"
  end

  test 'domain uniqueness' do
    CrawlSourceRule.create!(domain: 'example.com', rule_type: :blacklist)
    dup = CrawlSourceRule.new(domain: 'example.com', rule_type: :whitelist)
    assert_not dup.valid?
    assert dup.errors[:domain].any?
  end

  test 'normalizes domain from URL' do
    rule = CrawlSourceRule.create!(domain: 'https://www.deliveroo.ie/restaurant/foo', rule_type: :blacklist)
    assert_equal 'www.deliveroo.ie', rule.domain
  end

  test 'blacklisted? returns true for blacklisted domains' do
    CrawlSourceRule.create!(domain: 'justeat.ie', rule_type: :blacklist)
    assert CrawlSourceRule.blacklisted?('https://www.justeat.ie/restaurant/foo')
    assert CrawlSourceRule.blacklisted?('justeat.ie')
  end

  test 'blacklisted? returns false for non-blacklisted domains' do
    assert_not CrawlSourceRule.blacklisted?('myrestaurant.com')
  end

  test 'whitelisted? returns true for whitelisted domains' do
    CrawlSourceRule.create!(domain: 'trusted-menus.com', rule_type: :whitelist)
    assert CrawlSourceRule.whitelisted?('trusted-menus.com')
  end

  test 'enum rule_types' do
    rule = CrawlSourceRule.new(domain: 'test.com')
    rule.rule_type = :blacklist
    assert rule.blacklist?

    rule.rule_type = :whitelist
    assert rule.whitelist?
  end

  test 'scopes filter correctly' do
    CrawlSourceRule.create!(domain: 'blocked.com', rule_type: :blacklist)
    CrawlSourceRule.create!(domain: 'allowed.com', rule_type: :whitelist)

    assert_equal 1, CrawlSourceRule.blacklisted.count
    assert_equal 1, CrawlSourceRule.whitelisted.count
  end
end
