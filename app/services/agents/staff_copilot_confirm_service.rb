# frozen_string_literal: true

module Agents
  # Agents::StaffCopilotConfirmService — executes a confirmed copilot action.
  #
  # SAFETY CONTRACT:
  #   - Only pre-registered tool names in ALLOWED_TOOLS are accepted.
  #   - Any unrecognised tool_name returns an error result without execution.
  #   - Pundit role checks are re-run here (not delegated to the client).
  #   - No raw SQL is ever accepted — only validated confirm_params hashes.
  #
  # Usage:
  #   result = Agents::StaffCopilotConfirmService.call(
  #     restaurant:     @restaurant,
  #     user:           current_user,
  #     tool_name:      'flag_item_unavailable',
  #     confirm_params: { menuitem_id: 42, hide: true },
  #   )
  #   result.success?  # => true / false
  #   result.message   # => String
  class StaffCopilotConfirmService
    ALLOWED_TOOLS = %w[
      flag_item_unavailable
      create_menu_item
      update_menu_item
      send_staff_message
    ].freeze

    Result = Struct.new(:success, :message, :data, keyword_init: true) do
      def success? = success
    end

    def self.call(**)
      new(**).call
    end

    def initialize(restaurant:, user:, tool_name:, confirm_params:)
      @restaurant     = restaurant
      @user           = user
      @tool_name      = tool_name.to_s
      @confirm_params = (confirm_params || {}).with_indifferent_access
    end

    def call
      unless ALLOWED_TOOLS.include?(@tool_name)
        return Result.new(
          success: false,
          message: "Unknown action: #{@tool_name}",
        )
      end

      case @tool_name
      when 'flag_item_unavailable' then execute_flag_item_unavailable
      when 'create_menu_item'      then execute_create_menu_item
      when 'update_menu_item'      then execute_update_menu_item
      when 'send_staff_message'    then execute_send_staff_message
      end
    rescue StandardError => e
      Rails.logger.error("[StaffCopilotConfirmService] Unexpected error in #{@tool_name}: #{e.message}\n#{e.backtrace&.first(3)&.join("\n")}")
      Result.new(success: false, message: 'An error occurred while executing the action.')
    end

    private

    # --------------------------------------------------------------------------
    # Tool executions
    # --------------------------------------------------------------------------

    def execute_flag_item_unavailable
      unless user_can_toggle_availability?
        return Result.new(success: false, message: "You don't have permission to change item availability.")
      end

      menuitem_id = @confirm_params[:menuitem_id].to_i
      hide        = ActiveModel::Type::Boolean.new.cast(@confirm_params[:hide])

      menuitem = Menuitem
        .joins(menusection: :menu)
        .where(menus: { restaurant_id: @restaurant.id })
        .find_by(id: menuitem_id)

      unless menuitem
        return Result.new(success: false, message: 'Menu item not found.')
      end

      menuitem.update!(hidden: hide)
      menuitem.expire_cache if menuitem.respond_to?(:expire_cache)

      status_text = hide ? '86\'d and hidden from the menu' : 'restored to the menu'
      Result.new(
        success: true,
        message: "#{menuitem.name} has been #{status_text}.",
        data: { menuitem_id: menuitem.id, item_name: menuitem.name, hidden: hide },
      )
    end

    def execute_create_menu_item
      unless user_can_create_menu_items?
        return Result.new(success: false, message: "You don't have permission to add menu items.")
      end

      menusection_id = @confirm_params[:menusection_id]
      name           = @confirm_params[:name].to_s.strip
      price_cents    = @confirm_params[:price_cents]
      description    = @confirm_params[:description].to_s.strip
      allergen_names = Array(@confirm_params[:allergen_names])

      if name.blank?
        return Result.new(success: false, message: 'Item name is required.')
      end

      section = Menusection
        .joins(:menu)
        .where(menus: { restaurant_id: @restaurant.id })
        .find_by(id: menusection_id)

      section ||= Menusection
        .joins(:menu)
        .where(menus: { restaurant_id: @restaurant.id, archived: false, status: 'active' })
        .order('menus.created_at ASC, menusections.sequence ASC')
        .first

      unless section
        return Result.new(success: false, message: 'No active menu section found. Please create a menu first.')
      end

      price_value = price_cents.present? ? (price_cents.to_f / 100) : 0.0

      menuitem = section.menuitems.build(
        name: name,
        description: description.presence,
        price: price_value,
        calories: 0,
        status: 'active',
        hidden: false,
        archived: false,
        sequence: (section.menuitems.maximum(:sequence) || 0) + 1,
      )

      unless menuitem.save
        return Result.new(success: false, message: "Could not create item: #{menuitem.errors.full_messages.join(', ')}")
      end

      # Attach allergens
      if allergen_names.any?
        attach_allergens(menuitem, allergen_names)
      end

      Result.new(
        success: true,
        message: "#{menuitem.name} has been added to #{section.name}.",
        data: { menuitem_id: menuitem.id, item_name: menuitem.name, section: section.name },
      )
    end

    def execute_update_menu_item
      unless user_can_edit_menu_items?
        return Result.new(success: false, message: "You don't have permission to edit menu items.")
      end

      menuitem_id  = @confirm_params[:menuitem_id].to_i
      price_cents  = @confirm_params[:price_cents]
      description  = @confirm_params[:description]

      if price_cents.present? && !user_can_edit_prices?
        return Result.new(success: false, message: "You don't have permission to change item prices.")
      end

      menuitem = Menuitem
        .joins(menusection: :menu)
        .where(menus: { restaurant_id: @restaurant.id })
        .find_by(id: menuitem_id)

      unless menuitem
        return Result.new(success: false, message: 'Menu item not found.')
      end

      updates = {}
      updates[:price]       = (price_cents.to_f / 100) if price_cents.present?
      updates[:description] = description.to_s.strip if description.present?

      if updates.empty?
        return Result.new(success: false, message: 'No changes specified.')
      end

      unless menuitem.update(updates)
        return Result.new(success: false, message: "Could not update item: #{menuitem.errors.full_messages.join(', ')}")
      end

      menuitem.expire_cache if menuitem.respond_to?(:expire_cache)

      Result.new(
        success: true,
        message: "#{menuitem.name} has been updated.",
        data: { menuitem_id: menuitem.id, item_name: menuitem.name },
      )
    end

    def execute_send_staff_message
      unless user_can_send_staff_messages?
        return Result.new(success: false, message: "You don't have permission to send staff messages.")
      end

      subject = @confirm_params[:subject].to_s.strip
      body    = @confirm_params[:body].to_s.strip

      if subject.blank? || body.blank?
        return Result.new(success: false, message: 'Message subject and body are required.')
      end

      # Deliver to all active managers and admins (plus the restaurant owner)
      recipients = staff_message_recipients

      if recipients.empty?
        return Result.new(success: false, message: 'No staff members found to message.')
      end

      recipients.each do |email|
        CopilotBriefingMailer.staff_briefing(
          restaurant: @restaurant,
          from_user: @user,
          to_email: email,
          subject: subject,
          body: body,
        ).deliver_later
      end

      Result.new(
        success: true,
        message: "Message sent to #{recipients.size} staff member(s).",
        data: { recipient_count: recipients.size },
      )
    end

    # --------------------------------------------------------------------------
    # Helpers
    # --------------------------------------------------------------------------

    def attach_allergens(menuitem, allergen_names)
      allergen_names.each do |name|
        allergyn = Allergyn.find_by('LOWER(name) = ?', name.downcase.strip)
        next unless allergyn

        MenuitemAllergynMapping.find_or_create_by(menuitem: menuitem, allergyn: allergyn)
      end
    rescue StandardError => e
      Rails.logger.warn("[StaffCopilotConfirmService] Allergen attachment failed: #{e.message}")
    end

    def staff_message_recipients
      # Owner email
      owner_email = @restaurant.user&.email

      # Active manager/admin employees with email
      employee_emails = Employee
        .where(restaurant_id: @restaurant.id, status: 'active', role: %w[manager admin])
        .pluck(:email)
        .compact
        .compact_blank

      ([owner_email] + employee_emails).uniq.compact
    end

    # --------------------------------------------------------------------------
    # Role checks
    # --------------------------------------------------------------------------

    def user_role
      return :owner if @restaurant.user_id == @user.id

      employee = @user.employees.find_by(restaurant_id: @restaurant.id)
      return :none unless employee&.active?

      employee.role.to_sym
    end

    def owner_or_manager?
      %i[owner manager admin].include?(user_role)
    end

    def user_can_toggle_availability?
      %i[owner manager admin staff].include?(user_role)
    end

    def user_can_create_menu_items?
      owner_or_manager?
    end

    def user_can_edit_menu_items?
      owner_or_manager?
    end

    def user_can_edit_prices?
      owner_or_manager?
    end

    def user_can_send_staff_messages?
      owner_or_manager?
    end
  end
end
