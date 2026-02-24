module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :true_user
    impersonates :user

    def connect
      self.current_user = find_verified_user
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
  end
end
