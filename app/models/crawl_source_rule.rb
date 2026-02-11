class CrawlSourceRule < ApplicationRecord
  enum :rule_type, {
    blacklist: 0,
    whitelist: 1,
  }

  belongs_to :created_by_user, class_name: 'User', optional: true

  validates :domain, presence: true, uniqueness: { case_sensitive: false }
  validates :rule_type, presence: true

  before_validation :normalize_domain

  scope :blacklisted, -> { where(rule_type: :blacklist) }
  scope :whitelisted, -> { where(rule_type: :whitelist) }

  # Check if a URL or domain is blacklisted (matches with or without www.)
  def self.blacklisted?(url_or_domain)
    candidates = domain_candidates(url_or_domain)
    return false if candidates.empty?

    blacklisted.where('LOWER(domain) IN (?)', candidates).exists?
  end

  # Check if a URL or domain is whitelisted (matches with or without www.)
  def self.whitelisted?(url_or_domain)
    candidates = domain_candidates(url_or_domain)
    return false if candidates.empty?

    whitelisted.where('LOWER(domain) IN (?)', candidates).exists?
  end

  def self.extract_domain(url_or_domain)
    str = url_or_domain.to_s.strip
    return str.downcase unless str.include?('/')

    URI.parse(str).host.to_s.downcase
  rescue URI::InvalidURIError
    str.downcase
  end

  def self.domain_candidates(url_or_domain)
    d = extract_domain(url_or_domain)
    return [] if d.blank?

    stripped = d.sub(/\Awww\./, '')
    [d, stripped, "www.#{stripped}"].uniq
  end

  private

  def normalize_domain
    self.domain = self.class.extract_domain(domain) if domain.present?
  end
end
