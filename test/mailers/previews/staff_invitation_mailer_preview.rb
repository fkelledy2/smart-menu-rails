# Preview all emails at http://localhost:3000/rails/mailers/staff_invitation_mailer
class StaffInvitationMailerPreview < ActionMailer::Preview
  def invite
    invitation = StaffInvitation.first || StaffInvitation.new(
      email: 'newstaff@example.com',
      role: 'staff',
    )
    StaffInvitationMailer.invite(invitation)
  end
end
