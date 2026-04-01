# frozen_string_literal: true

module CostInsights
  # Aggregates infra + vendor + staff costs for a given month and currency.
  class TotalCalculator
    PRODUCTION_ENVIRONMENTS = %w[production].freeze

    Result = Struct.new(
      :heroku_cents,
      :vendor_cents,
      :staff_cents,
      :total_cents,
      :month,
      :currency,
      :breakdown,
      keyword_init: true,
    ) do
      def total_euros
        total_cents / 100.0
      end
    end

    def self.calculate(month:, currency: 'EUR')
      new(month: month, currency: currency).calculate
    end

    def initialize(month:, currency:)
      @month = month.beginning_of_month
      @currency = currency
    end

    def calculate
      heroku_cents = heroku_total
      vendor_cents = vendor_total
      staff_cents  = staff_total

      Result.new(
        heroku_cents: heroku_cents,
        vendor_cents: vendor_cents,
        staff_cents: staff_cents,
        total_cents: heroku_cents + vendor_cents + staff_cents,
        month: @month,
        currency: @currency,
        breakdown: build_breakdown,
      )
    end

    private

    def heroku_total
      InfraCostSnapshot
        .for_month(@month)
        .for_environment('production')
        .sum(:estimated_monthly_cost_cents)
    end

    def vendor_total
      ExternalServiceMonthlyCost
        .for_month(@month)
        .for_currency(@currency)
        .sum(:amount_cents)
    end

    def staff_total
      snapshot = StaffCostSnapshot.for_month(@month).for_currency(@currency).first
      snapshot&.total_cost_cents || 0
    end

    def build_breakdown
      heroku_by_env = InfraCostSnapshot
        .for_month(@month)
        .group(:environment)
        .sum(:estimated_monthly_cost_cents)

      vendor_by_service = ExternalServiceMonthlyCost
        .for_month(@month)
        .for_currency(@currency)
        .group(:service)
        .sum(:amount_cents)

      staff_snap = StaffCostSnapshot.for_month(@month).for_currency(@currency).first

      {
        heroku: heroku_by_env,
        vendor: vendor_by_service,
        staff: {
          support: staff_snap&.support_cost_cents || 0,
          staff: staff_snap&.staff_cost_cents || 0,
          other_ops: staff_snap&.other_ops_cost_cents || 0,
        },
      }
    end
  end
end
