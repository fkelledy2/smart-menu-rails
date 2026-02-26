class StaffInvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @restaurant = invitation.restaurant
    @accept_url = accept_staff_invitation_url(token: invitation.token)

    mail(
      to: invitation.email,
      subject: "You've been invited to join #{@restaurant.name} on Mellow Menu",
    )
  end
end
