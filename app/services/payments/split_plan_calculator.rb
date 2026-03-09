module Payments
  class SplitPlanCalculator
    Result = Struct.new(:shares, :errors, keyword_init: true) do
      def success?
        errors.blank?
      end
    end

    def initialize(ordr:, split_method:, participant_ids:, custom_amounts_cents: {}, percentage_basis_points: {}, item_assignments: {})
      @ordr = ordr
      @split_method = split_method.to_s
      @participants = ordr.ordrparticipants.where(id: participant_ids).order(:id)
      @custom_amounts_cents = normalize_hash(custom_amounts_cents)
      @percentage_basis_points = normalize_hash(percentage_basis_points)
      @item_assignments = normalize_hash(item_assignments)
    end

    def call
      return Result.new(errors: ['Order must be billrequested to split']) unless @ordr.billrequested?
      return Result.new(errors: ['Need at least 1 participant']) if @participants.empty?

      active_participants = @ordr.ordrparticipants.where(role: Ordrparticipant.roles['customer']).where.not(sessionid: [nil, ''])
      inactive_participant_ids = @participants.pluck(:id) - active_participants.pluck(:id)
      return Result.new(errors: ['Only active order participants can be included in split plans']) if inactive_participant_ids.any?

      case @split_method
      when 'equal'
        build_equal_split
      when 'custom'
        build_custom_split
      when 'percentage'
        build_percentage_split
      when 'item_based'
        build_item_based_split
      else
        Result.new(errors: ['Unsupported split method'])
      end
    end

    private

    def build_equal_split
      amounts = distribute_cents(subtotal_cents, @participants.length)
      Result.new(shares: build_share_hashes(amounts))
    end

    def build_custom_split
      amounts = @participants.map { |participant| @custom_amounts_cents[participant.id].to_i }
      return Result.new(errors: ['Custom split totals must equal order subtotal']) unless amounts.sum == subtotal_cents

      Result.new(shares: build_share_hashes(amounts))
    end

    def build_percentage_split
      points = @participants.map { |participant| @percentage_basis_points[participant.id].to_i }
      return Result.new(errors: ['Percentage split must total 100%']) unless points.sum == 10_000

      base_amounts = points.map { |value| (subtotal_cents * value) / 10_000 }
      remainder = subtotal_cents - base_amounts.sum
      amounts = base_amounts.each_with_index.map { |amount, index| amount + (index < remainder ? 1 : 0) }

      Result.new(shares: build_share_hashes(amounts, percentage_basis_points: points))
    end

    def build_item_based_split
      payable_items = @ordr.ordritems.where.not(status: Ordritem.statuses['removed']).order(:id)
      assigned_item_ids = @item_assignments.values.flatten.map(&:to_i)

      return Result.new(errors: ['All payable items must be assigned']) unless payable_items.pluck(:id).sort == assigned_item_ids.sort
      return Result.new(errors: ['Items cannot be assigned more than once']) unless assigned_item_ids.uniq.length == assigned_item_ids.length

      item_totals = @participants.map do |participant|
        ids = Array(@item_assignments[participant.id]).map(&:to_i)
        payable_items.select { |item| ids.include?(item.id) }.sum do |item|
          quantity = item.respond_to?(:quantity) ? item.quantity.to_i : 1
          quantity = 1 if quantity <= 0
          (item.ordritemprice.to_f * 100.0).round * quantity
        end
      end

      return Result.new(errors: ['Item split totals must equal order subtotal']) unless item_totals.sum == subtotal_cents

      Result.new(shares: build_share_hashes(item_totals, item_assignments: @item_assignments))
    end

    def build_share_hashes(base_amounts, percentage_basis_points: nil, item_assignments: nil)
      allocation = proportional_allocation(base_amounts)

      @participants.each_with_index.map do |participant, index|
        {
          ordrparticipant: participant,
          amount_cents: allocation[:totals][index],
          base_amount_cents: base_amounts[index],
          tax_amount_cents: allocation[:tax][index],
          tip_amount_cents: allocation[:tip][index],
          service_charge_amount_cents: allocation[:service][index],
          percentage_basis_points: percentage_basis_points&.[](index),
          item_ids: item_assignments ? Array(item_assignments[participant.id]).map(&:to_i) : [],
        }
      end
    end

    def proportional_allocation(base_amounts)
      ratio_source = base_amounts.sum.positive? ? base_amounts : Array.new(base_amounts.length, 1)
      tax = allocate_component(tax_cents, ratio_source)
      tip = allocate_component(tip_cents, ratio_source)
      service = allocate_component(service_cents, ratio_source)
      totals = base_amounts.each_with_index.map { |amount, index| amount + tax[index] + tip[index] + service[index] }

      delta = total_cents - totals.sum
      totals[0] += delta if delta != 0 && totals.any?

      { tax: tax, tip: tip, service: service, totals: totals }
    end

    def allocate_component(total_component_cents, weights)
      return Array.new(weights.length, 0) if total_component_cents <= 0

      weight_sum = weights.sum
      allocated = weights.map { |weight| (total_component_cents * weight) / weight_sum }
      remainder = total_component_cents - allocated.sum
      allocated.each_with_index.map { |value, index| value + (index < remainder ? 1 : 0) }
    end

    def distribute_cents(amount, count)
      base = amount / count
      remainder = amount % count
      Array.new(count) { |index| base + (index < remainder ? 1 : 0) }
    end

    def subtotal_cents
      total_cents - tax_cents - tip_cents - service_cents
    end

    def total_cents
      component_cents(@ordr.gross)
    end

    def tax_cents
      component_cents(@ordr.tax)
    end

    def tip_cents
      component_cents(@ordr.tip)
    end

    def service_cents
      component_cents(@ordr.service)
    end

    def component_cents(value)
      (value.to_f * 100.0).round
    end

    def normalize_hash(value)
      value.to_h.transform_keys(&:to_i)
    rescue StandardError
      {}
    end
  end
end
