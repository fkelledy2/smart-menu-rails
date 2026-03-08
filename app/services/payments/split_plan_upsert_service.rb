module Payments
  class SplitPlanUpsertService
    Result = Struct.new(:plan, :errors, keyword_init: true) do
      def success?
        errors.blank?
      end
    end

    def initialize(ordr:, actor:, split_method:, participant_ids:, custom_amounts_cents: {}, percentage_basis_points: {}, item_assignments: {})
      @ordr = ordr
      @actor = actor
      @split_method = split_method
      @participant_ids = participant_ids
      @custom_amounts_cents = custom_amounts_cents
      @percentage_basis_points = percentage_basis_points
      @item_assignments = item_assignments
    end

    def call
      plan = @ordr.ordr_split_plan || @ordr.build_ordr_split_plan(created_by_user: @actor)
      return Result.new(errors: ['Split plan is frozen']) if plan.persisted? && plan.any_share_in_flight?

      calculation = Payments::SplitPlanCalculator.new(
        ordr: @ordr,
        split_method: @split_method,
        participant_ids: @participant_ids,
        custom_amounts_cents: @custom_amounts_cents,
        percentage_basis_points: @percentage_basis_points,
        item_assignments: @item_assignments,
      ).call
      return Result.new(errors: Array(calculation.errors)) unless calculation.success?

      ActiveRecord::Base.transaction do
        plan.assign_attributes(
          split_method: @split_method,
          plan_status: :validated,
          updated_by_user: @actor,
          participant_count: calculation.shares.length,
        )
        plan.save!

        plan.ordr_split_item_assignments.delete_all
        plan.ordr_split_payments.delete_all

        Array(calculation.shares).each_with_index do |share, index|
          split_payment = plan.ordr_split_payments.create!(
            ordr: @ordr,
            ordrparticipant: share[:ordrparticipant],
            amount_cents: share[:amount_cents],
            currency: @ordr.restaurant.currency.presence || 'USD',
            status: :requires_payment,
            split_method: @split_method,
            position: index,
            base_amount_cents: share[:base_amount_cents],
            tax_amount_cents: share[:tax_amount_cents],
            tip_amount_cents: share[:tip_amount_cents],
            service_charge_amount_cents: share[:service_charge_amount_cents],
            percentage_basis_points: share[:percentage_basis_points],
          )

          Array(share[:item_ids]).each do |ordritem_id|
            plan.ordr_split_item_assignments.create!(
              ordritem_id: ordritem_id,
              ordr_split_payment: split_payment,
            )
          end
        end
      end

      Result.new(plan: plan.reload)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(errors: [e.record.errors.full_messages.to_sentence.presence || e.message])
    end
  end
end
