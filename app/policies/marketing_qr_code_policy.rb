# frozen_string_literal: true

class MarketingQrCodePolicy < ApplicationPolicy
  def index?
    mellow_admin?
  end

  def show?
    mellow_admin?
  end

  def create?
    mellow_admin?
  end

  def new?
    create?
  end

  def update?
    mellow_admin?
  end

  def edit?
    update?
  end

  def destroy?
    mellow_admin?
  end

  def link?
    mellow_admin?
  end

  def unlink?
    mellow_admin?
  end

  def print?
    mellow_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if mellow_admin?

      scope.none
    end

    private

    def mellow_admin?
      user.respond_to?(:email) && user.email.to_s.end_with?('@mellow.menu')
    end
  end

  private

  def mellow_admin?
    user.respond_to?(:email) && user.email.to_s.end_with?('@mellow.menu')
  end
end
