module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :true_user, :current_dining_session
    impersonates :user

    def connect
      self.current_user = find_verified_user
      self.current_dining_session = find_dining_session
      if current_user
        logger.add_tags 'ActionCable', "User #{current_user.id}"
      end
    end

    protected

    def find_verified_user
      if (current_user = env['warden'].user)
        current_user
      end
    rescue UncaughtThrowError
      # Devise's timeoutable hook throws :warden when the session is
      # expired or absent (e.g. unauthenticated customer smartmenu pages).
      # Return nil so the connection proceeds without a current_user.
      nil
    end

    def find_dining_session
      token = request.session[:dining_session_token]
      return nil if token.blank?

      DiningSession.valid.find_by(session_token: token)
    rescue StandardError
      nil
    end
  end
end
