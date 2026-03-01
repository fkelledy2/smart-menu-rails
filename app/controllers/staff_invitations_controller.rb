class StaffInvitationsController < ApplicationController
  before_action :authenticate_user!, only: [:create]
  after_action :verify_authorized, only: [:create]

  # POST /restaurants/:restaurant_id/staff_invitations
  def create
    @restaurant = Restaurant.find(params[:restaurant_id])
    @invitation = @restaurant.staff_invitations.new(
      email: params[:staff_invitation][:email]&.strip&.downcase,
      role: params[:staff_invitation][:role],
      invited_by: current_user,
    )

    authorize @invitation

    # Check for existing pending invitation for same email + restaurant
    existing = @restaurant.staff_invitations.active.find_by(email: @invitation.email)
    if existing
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('staff_invite_form',
                                                    partial: 'staff_invitations/invite_form',
                                                    locals: { restaurant: @restaurant, error: I18n.t('staff_invitations.already_invited') },)
        end
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'staff'), alert: I18n.t('staff_invitations.already_invited') }
      end
      return
    end

    # Check if email already belongs to an active employee
    existing_user = User.find_by(email: @invitation.email)
    if existing_user && @restaurant.employees.exists?(user: existing_user, archived: false)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('staff_invite_form',
                                                    partial: 'staff_invitations/invite_form',
                                                    locals: { restaurant: @restaurant, error: I18n.t('staff_invitations.already_staff') },)
        end
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'staff'), alert: I18n.t('staff_invitations.already_staff') }
      end
      return
    end

    if @invitation.save
      StaffInvitationMailer.invite(@invitation).deliver_later

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('staff_invite_form', ''),
            turbo_stream.replace(
              'restaurant_content',
              partial: 'restaurants/sections/staff_2025',
              locals: { restaurant: @restaurant, filter: 'all' },
            ),
          ]
        end
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'staff'), notice: I18n.t('staff_invitations.sent', email: @invitation.email) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('staff_invite_form',
                                                    partial: 'staff_invitations/invite_form',
                                                    locals: { restaurant: @restaurant, invitation: @invitation, error: @invitation.errors.full_messages.join(', ') },)
        end
        format.html { redirect_to edit_restaurant_path(@restaurant, section: 'staff'), alert: @invitation.errors.full_messages.join(', ') }
      end
    end
  end

  # GET /staff_invitations/:token/accept
  def accept
    @invitation = StaffInvitation.find_by(token: params[:token])

    if @invitation.nil?
      redirect_to root_path, alert: I18n.t('staff_invitations.not_found')
      return
    end

    if @invitation.accepted?
      redirect_to new_user_session_path, notice: I18n.t('staff_invitations.already_accepted')
      return
    end

    if @invitation.expired? || @invitation.revoked?
      redirect_to root_path, alert: I18n.t('staff_invitations.expired')
      return
    end

    # Store the invitation token in the session so we can process it after sign in
    session[:staff_invitation_token] = @invitation.token

    if user_signed_in?
      # User is already signed in — accept immediately
      employee = @invitation.accept!(current_user)
      if employee
        redirect_to edit_restaurant_path(@invitation.restaurant, section: 'staff'),
                    notice: I18n.t('staff_invitations.accepted', restaurant: @invitation.restaurant.name)
      else
        redirect_to root_path, alert: I18n.t('staff_invitations.accept_failed')
      end
    else
      # Show the accept landing page with sign in / sign up links
      render :accept, layout: 'application'
    end
  end
end
