class ContactPolicy < ApplicationPolicy
  def new?
    true # Public contact form
  end

  def create?
    true # Public contact form
  end
end
