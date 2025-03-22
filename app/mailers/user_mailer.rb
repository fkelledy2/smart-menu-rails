class UserMailer < ApplicationMailer
    default from: 'admin@mellow.menu'

    def welcome_email(user)
        @user = user
        mail(to:@user.email, subject: 'Welcome to Mellow Menu')
    end

end
