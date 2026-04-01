# frozen_string_literal: true

module Heroku
  # Computes monthly infra cost totals from inventory snapshots and coefficient tables.
  # Groups by environment and persists to infra_cost_snapshots.
  class CostRollupService
    # Configurable for ephemeral environments (review apps etc.)
    EPHEMERAL_CONFIG = {
      assumed_concurrent_instances: 2,
      avg_lifetime_days: 7,
    }.freeze

    Result = Struct.new(:snapshots, :errors, keyword_init: true) do
      def success?
        errors.empty?
      end
    end

    def self.rollup(month:, space_name: 'smart-menu', created_by_user_id: nil)
      new(month: month, space_name: space_name, created_by_user_id: created_by_user_id).rollup
    end

    def initialize(month:, space_name:, created_by_user_id:)
      @month = month.beginning_of_month
      @space_name = space_name
      @created_by_user_id = created_by_user_id
    end

    def rollup
      snapshots_by_env = HerokuAppInventorySnapshot
        .for_space(@space_name)
        .where(captured_at: @month..@month.end_of_month)
        .group_by(&:environment)

      if snapshots_by_env.empty?
        return Result.new(
          snapshots: [],
          errors: ["No inventory snapshots found for #{@space_name} in #{@month.strftime('%Y-%m')}"],
        )
      end

      dyno_costs = HerokuDynoSizeCost.all.index_by { |c| c.dyno_size.downcase }
      addon_costs = HerokuAddonPlanCost.all.index_by { |c| "#{c.addon_service}:#{c.plan_name}" }

      saved = []
      errors = []

      snapshots_by_env.each do |env, app_snapshots|
        # De-duplicate: use the latest snapshot per app for the month
        latest_per_app = app_snapshots
          .group_by(&:app_name)
          .transform_values { |snaps| snaps.max_by(&:captured_at) }
          .values

        env_cost_cents = 0
        formation_rollup = {}
        addons_rollup = {}

        latest_per_app.each do |snapshot|
          # Formation cost
          (snapshot.formation_json || []).each do |proc|
            size     = proc['size'].to_s.downcase
            quantity = proc['quantity'].to_i
            ptype    = proc['type'].to_s

            cost_per = dyno_costs[size]&.cost_cents_per_month || 0

            if env == 'ephemeral'
              # Scale by fraction of month actually used
              fraction = (EPHEMERAL_CONFIG[:avg_lifetime_days] / 30.0) *
                         EPHEMERAL_CONFIG[:assumed_concurrent_instances]
              cost_per = (cost_per * fraction).round
            end

            line_total = cost_per * quantity
            env_cost_cents += line_total

            formation_rollup[ptype] ||= { size: size, quantity: 0, cost_cents: 0 }
            formation_rollup[ptype][:quantity] += quantity
            formation_rollup[ptype][:cost_cents] += line_total
          end

          # Add-on cost
          (snapshot.addons_json || []).each do |addon|
            service  = addon.dig('addon_service', 'name').to_s
            plan     = addon.dig('plan', 'name').to_s
            full_key = "#{service}:#{plan}"

            cost_per = addon_costs[full_key]&.cost_cents_per_month || 0
            env_cost_cents += cost_per

            addons_rollup[full_key] ||= { service: service, plan: plan, count: 0, cost_cents: 0 }
            addons_rollup[full_key][:count] += 1
            addons_rollup[full_key][:cost_cents] += cost_per
          end
        end

        record = InfraCostSnapshot.find_or_initialize_by(
          month: @month,
          provider: 'heroku',
          space_name: @space_name,
          environment: env,
        )

        record.assign_attributes(
          estimated_monthly_cost_cents: env_cost_cents,
          app_count: latest_per_app.size,
          formation_rollup_json: formation_rollup,
          addons_rollup_json: addons_rollup,
          updated_by_user_id: @created_by_user_id,
        )

        record.created_by_user_id = @created_by_user_id if record.new_record?

        if record.save
          saved << record
        else
          errors << { environment: env, errors: record.errors.full_messages }
        end
      end

      Result.new(snapshots: saved, errors: errors)
    end
  end
end
