# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user || User.new # Guest user (no admin privileges)
    @record = record
  end

  def index?
    return true if super_admin?

    false
  end

  def show?
    return true if super_admin?

    false
  end

  def create?
    return true if super_admin?

    false
  end

  def new?
    create?
  end

  def update?
    return true if super_admin?

    false
  end

  def edit?
    update?
  end

  def destroy?
    return true if super_admin?

    false
  end

  private

  def super_admin?
    user.respond_to?(:super_admin?) && user.super_admin?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user.respond_to?(:super_admin?) && user.super_admin?

      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
