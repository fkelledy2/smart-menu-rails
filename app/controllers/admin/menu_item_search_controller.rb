# frozen_string_literal: true

class Admin::MenuItemSearchController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  after_action :verify_authorized

  def index
    authorize %i[admin menu_item_search]

    menu_id = params[:menu_id].to_i
    render json: stats_for_menu(menu_id)
  end

  def reindex
    authorize %i[admin menu_item_search], :reindex?

    unless vector_search_enabled?
      render json: { ok: false, error: 'vector_search_disabled' }, status: :unprocessable_content
      return
    end

    menu_id = params[:menu_id].to_i
    locale = params[:locale].presence

    MenuItemSearchIndexJob.perform_async(menu_id, locale)

    render json: { ok: true, enqueued: true, menu_id: menu_id, locale: locale }
  end

  private

  def vector_search_enabled?
    v = ENV.fetch('SMART_MENU_VECTOR_SEARCH_ENABLED', nil)
    return true if v.nil? || v.to_s.strip == ''

    v.to_s.downcase == 'true'
  end

  def stats_for_menu(menu_id)
    raise ArgumentError, 'menu_id is required' if menu_id <= 0

    menu = Menu.find(menu_id)
    restaurant = menu.restaurant

    locales = Restaurantlocale.where(restaurant_id: restaurant.id, status: 1).pluck(:locale).map { |l| normalize_locale(l) }
    locales = locales.filter_map(&:presence).uniq
    locales = ['en'] if locales.empty?

    menuitem_count = Menuitem.joins(:menusection).where(menusections: { menu_id: menu.id }).count

    per_locale = locales.map do |loc|
      scope = MenuItemSearchDocument.where(menu_id: menu.id, locale: loc)
      total_docs = scope.count
      embedded_docs = scope.where.not(embedding: nil).count

      {
        locale: loc,
        docs: total_docs,
        embedded: embedded_docs,
        missing_embeddings: total_docs - embedded_docs,
      }
    end

    {
      menu_id: menu.id,
      restaurant_id: restaurant.id,
      menuitems: menuitem_count,
      locales: per_locale,
    }
  rescue ActiveRecord::RecordNotFound
    { ok: false, error: 'menu_not_found', menu_id: menu_id }
  rescue ArgumentError => e
    { ok: false, error: e.message, menu_id: menu_id }
  end

  def normalize_locale(locale)
    s = locale.to_s.strip
    s = s.split(/[-_]/).first.to_s.downcase
    s.presence || 'en'
  end
end
