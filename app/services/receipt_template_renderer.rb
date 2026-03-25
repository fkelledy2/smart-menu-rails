class ReceiptTemplateRenderer
  # Produces a plain-text receipt body for SMS or fallback use.
  # HTML rendering is handled directly in the mailer view.

  def initialize(ordr)
    @ordr = ordr
    @restaurant = ordr.restaurant
  end

  def receipt_items
    @ordr.ordritems
      .where.not(status: :removed)
      .includes(:menuitem)
      .map do |item|
        {
          name: item.menuitem&.name.to_s,
          quantity: item.quantity,
          unit_price: item.ordritemprice.to_f,
          line_total: item.total_price.to_f,
        }
      end
  end

  def subtotal
    receipt_items.sum { |i| i[:line_total] }
  end

  def tax_amount
    @ordr.tax.to_f
  end

  def tip_amount
    @ordr.tip.to_f
  end

  def grand_total
    @ordr.gross.to_f
  end

  def order_number
    @ordr.id.to_s
  end

  def order_date
    (@ordr.paidAt || @ordr.created_at).strftime('%d %b %Y, %H:%M')
  end

  def restaurant_name
    @restaurant.name.to_s
  end

  def restaurant_address
    parts = [
      @restaurant.address1,
      @restaurant.city,
      @restaurant.postcode,
      @restaurant.country,
    ].compact_blank
    parts.join(', ')
  end

  def restaurant_image_url
    @restaurant.image_url if @restaurant.respond_to?(:image) && @restaurant.image
  end

  def currency_symbol
    case @restaurant.currency.to_s.upcase
    when 'EUR' then '€'
    when 'GBP' then '£'
    when 'USD' then '$'
    when 'AUD' then 'A$'
    when 'CAD' then 'C$'
    else @restaurant.currency.to_s
    end
  end

  def format_currency(amount)
    "#{currency_symbol}#{'%.2f' % amount.to_f}"
  end

  def as_plain_text
    lines = []
    lines << restaurant_name
    lines << restaurant_address unless restaurant_address.blank?
    lines << ''
    lines << "Receipt — Order ##{order_number}"
    lines << order_date
    lines << ('-' * 40)

    receipt_items.each do |item|
      lines << "#{item[:quantity]}x #{item[:name]}  #{format_currency(item[:line_total])}"
    end

    lines << ('-' * 40)
    lines << "Subtotal:  #{format_currency(subtotal)}"
    lines << "Tax:       #{format_currency(tax_amount)}" if tax_amount > 0
    lines << "Tip:       #{format_currency(tip_amount)}" if tip_amount > 0
    lines << "Total:     #{format_currency(grand_total)}"
    lines << ''
    lines << 'Thank you for dining with us!'
    lines.join("\n")
  end
end
