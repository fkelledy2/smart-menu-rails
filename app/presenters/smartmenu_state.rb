# frozen_string_literal: true

class SmartmenuState
  def self.for_context(menu:, restaurant:, tablesetting:, open_order:, ordrparticipant:, menuparticipant:, session_id:)
    locale = determine_locale(restaurant: restaurant, ordrparticipant: ordrparticipant, menuparticipant: menuparticipant)
    order_hash = order_payload(open_order, locale)
    # Visibility flags derived from counts (server source of truth)
    # Single source of truth for Request Bill visibility
    display_request_bill = order_hash[:totalCount].to_i.positive? && order_hash[:openedCount].to_i.zero?
    {
      version: 1,
      session: session_id,
      order: order_hash,
      tableId: tablesetting&.id&.to_s,
      employeeId: (ordrparticipant&.employee_id || nil)&.to_s,
      menuId: menu&.id&.to_s,
      restaurant: {
        id: restaurant&.id&.to_s,
        allowAlcohol: !restaurant&.allow_alcohol.nil?,
        allowedNow: !(restaurant.respond_to?(:alcohol_allowed_now?) && restaurant.alcohol_allowed_now?).nil?,
        verifyAgeText: I18n.t('smartmenus.alcohol.verify_age', default: ''),
        salesDisabledText: I18n.t('smartmenus.alcohol.sales_disabled', default: ''),
        policyBlockedText: I18n.t('smartmenus.alcohol.policy_blocked', default: 'Alcohol not available at this time.'),
      },
      totals: totals_for(open_order, restaurant),
      flags: {
        displayRequestBill: display_request_bill,
        payVisible: (order_hash[:status].to_s == 'billrequested'),
        menuItemsEnabled: order_hash[:id].present? && %w[billrequested paid closed].exclude?(order_hash[:status].to_s),
      },
      participants: {
        orderParticipantId: ordrparticipant&.id&.to_s,
        menuParticipantId: menuparticipant&.id&.to_s,
      },
      splitPlan: split_plan_payload(open_order, ordrparticipant),
    }
  end

  def self.determine_locale(restaurant:, ordrparticipant:, menuparticipant:)
    # If staff (employee) is present, do not use participant locales; use restaurant default
    if ordrparticipant&.employee_id.present?
      return (restaurant&.defaultLocale&.locale.presence || I18n.default_locale).to_s.downcase
    end

    (ordrparticipant&.preferredlocale.presence ||
      menuparticipant&.preferredlocale.presence ||
      restaurant&.defaultLocale&.locale.presence ||
      I18n.default_locale).to_s.downcase
  end

  def self.order_payload(order, locale)
    return { id: nil, status: nil } unless order

    # Prefer ordritems; if missing, derive from ordractions to mirror ERB rendering
    base_items = Array(order.ordritems)
    if base_items.empty? && order.respond_to?(:ordractions)
      base_items = Array(order.ordractions).filter_map(&:ordritem)
    end

    items = base_items.uniq(&:id).map do |item|
      # Localised name with safe fallbacks
      name = begin
        mi = item.menuitem
        if mi.respond_to?(:localised_name)
          mi.localised_name(locale)
        else
          mi&.name
        end
      rescue StandardError
        item.menuitem&.name
      end

      # Price: prefer ordritemprice, else fall back to menuitem price
      price = begin
        p = item.ordritemprice
        if p.nil? && item.menuitem && item.menuitem.respond_to?(:price)
          item.menuitem.price
        else
          p
        end
      rescue StandardError
        item.ordritemprice
      end

      {
        id: item.id,
        menuitem_id: item.menuitem_id,
        name: name.to_s,
        price: price.to_f,
        quantity: item.try(:quantity) || 1,
        status: item.status.to_s,
        size_name: item.try(:size_name),
      }
    end
    opened_count         = items.count { |i| i[:status] == 'opened' }
    removed_count        = items.count { |i| i[:status] == 'removed' }
    ordered_only_count   = items.count { |i| i[:status] == 'ordered' }
    preparing_count      = items.count { |i| i[:status] == 'preparing' }
    ready_count          = items.count { |i| i[:status] == 'ready' }
    delivered_count      = items.count { |i| i[:status] == 'delivered' }
    billrequested_count  = items.count { |i| i[:status] == 'billrequested' }
    paid_count           = items.count { |i| i[:status] == 'paid' }
    closed_count         = items.count { |i| i[:status] == 'closed' }

    total_count = items.size

    {
      id: order.id.to_s,
      status: order.status.to_s,
      items: items,
      # existing aggregates (kept for compatibility)
      addedCount: opened_count,
      orderedCount: (ordered_only_count + preparing_count + ready_count + delivered_count),
      # per-status counts (authoritative for consumers)
      totalCount: total_count,
      openedCount: opened_count,
      removedCount: removed_count,
      orderedOnlyCount: ordered_only_count,
      preparingCount: preparing_count,
      readyCount: ready_count,
      deliveredCount: delivered_count,
      billrequestedCount: billrequested_count,
      paidCount: paid_count,
      closedCount: closed_count,
    }
  end

  # Split Plan WebSocket Payload
  # 
  # Generates the split plan data included in SmartmenuState broadcasts.
  # This enables realtime updates to the customer split bill UI when:
  # - Another participant creates/modifies the split plan
  # - Staff updates the split plan
  # - Payment status changes (share becomes pending/succeeded)
  # - Plan becomes frozen (after first payment initiated)
  # 
  # Consumed by: app/javascript/controllers/split_bill_controller.js
  # via 'state:update' event listener
  def self.split_plan_payload(order, ordrparticipant)
    return nil unless order

    plan = order.ordr_split_plan
    return nil unless plan

    my_share = plan.ordr_split_payments.find_by(ordrparticipant: ordrparticipant) if ordrparticipant

    {
      id: plan.id.to_s,
      splitMethod: plan.split_method.to_s,
      planStatus: plan.plan_status.to_s,
      participantCount: plan.participant_count,
      frozen: plan.split_frozen?,
      allSettled: plan.all_shares_settled?,
      myShare: my_share ? {
        id: my_share.id.to_s,
        amountCents: my_share.amount_cents,
        status: my_share.status.to_s,
        canPay: my_share.pay_ready?,
      } : nil,
    }
  end

  def self.totals_for(order, restaurant)
    return nil unless order && restaurant

    currency = ISO4217::Currency.from_code(restaurant.currency.presence || 'USD')

    nett = order.nett.to_f
    tax = order.tax.to_f
    service = order.service.to_f
    covercharge = order.covercharge.to_f
    tip = order.tip.to_f
    gross = order.gross.to_f

    if gross <= 0
      begin
        items_total = if order.respond_to?(:ordritems)
                        order.ordritems.sum('ordritemprice * quantity').to_f
                      else
                        0.0
                      end
        if items_total.positive?
          nett = items_total
          gross = items_total
        end
      rescue StandardError
        nil
      end
    end
    {
      nett: nett,
      tax: tax,
      service: service,
      covercharge: covercharge,
      tip: tip,
      gross: gross,
      currency: {
        code: currency.code,
        symbol: currency.symbol.to_s,
      },
    }
  end
end
