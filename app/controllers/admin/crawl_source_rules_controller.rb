module Admin
  class CrawlSourceRulesController < ::ApplicationController
    skip_around_action :switch_locale
    skip_before_action :set_current_employee
    skip_before_action :set_permissions
    skip_before_action :redirect_to_onboarding_if_needed

    before_action :authenticate_user!
    before_action :ensure_admin!
    before_action :require_super_admin!

    before_action :set_rule, only: %i[edit update destroy]

    def index
      scope = CrawlSourceRule.order(created_at: :desc)

      rule_type = params[:rule_type].to_s.presence
      if rule_type.present? && CrawlSourceRule.rule_types.key?(rule_type)
        scope = scope.where(rule_type: CrawlSourceRule.rule_types[rule_type])
      end

      @rule_type = rule_type
      @rules = scope.limit(500)
    end

    def new
      @rule = CrawlSourceRule.new
    end

    def edit; end

    def create
      @rule = CrawlSourceRule.new(rule_params)
      @rule.created_by_user = current_user

      if @rule.save
        redirect_to admin_crawl_source_rules_path, notice: "#{@rule.rule_type.humanize} rule created for #{@rule.domain}", status: :see_other
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @rule.update(rule_params)
        redirect_to admin_crawl_source_rules_path, notice: 'Rule updated', status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @rule.destroy!
      redirect_to admin_crawl_source_rules_path, notice: 'Rule deleted', status: :see_other
    end

    private

    def set_rule
      @rule = CrawlSourceRule.find(params[:id])
    end

    def rule_params
      params.require(:crawl_source_rule).permit(:domain, :rule_type, :reason)
    end

    def ensure_admin!
      redirect_to root_path, alert: 'Access denied.' unless current_user&.admin?
    end

    def require_super_admin!
      return if current_user&.admin? && current_user.super_admin?

      redirect_to root_path, alert: 'Access denied. Super admin privileges required.'
    end
  end
end
