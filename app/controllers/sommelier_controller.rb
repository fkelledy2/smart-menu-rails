# frozen_string_literal: true

class SommelierController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_employee, raise: false
  skip_before_action :set_permissions, raise: false
  skip_before_action :redirect_to_onboarding_if_needed, raise: false
  skip_around_action :switch_locale, raise: false

  before_action :set_smartmenu
  before_action :set_menu

  # POST /smartmenus/:smartmenu_id/sommelier/recommend
  def recommend
    preferences = {
      smoky: ActiveModel::Type::Boolean.new.cast(params[:smoky]),
      taste: params[:taste].to_s.presence || 'dry',
      budget: params[:budget].to_i.clamp(1, 3),
    }

    recommender = BeverageIntelligence::Recommender.new
    results = recommender.recommend_for_guest(
      menu: @menu,
      preferences: preferences,
      limit: 3,
    )

    render json: {
      recommendations: results.map { |r| format_recommendation(r) },
      preferences: preferences,
    }
  end

  # POST /smartmenus/:smartmenu_id/sommelier/recommend_wine
  def recommend_wine
    preferences = {
      wine_color: params[:wine_color].to_s.presence || 'no_preference',
      body: params[:body].to_s.presence || 'medium',
      taste: params[:taste].to_s.presence || 'dry',
      budget: params[:budget].to_i.clamp(1, 3),
    }

    recommender = BeverageIntelligence::Recommender.new
    results = recommender.recommend_wines_for_guest(
      menu: @menu,
      preferences: preferences,
      limit: 3,
    )

    render json: {
      recommendations: results.map { |r| format_wine_recommendation(r) },
      preferences: preferences,
    }
  end

  # GET /smartmenus/:smartmenu_id/sommelier/pairings/:menuitem_id
  def pairings
    menuitem = @menu.menuitems.find(params[:menuitem_id])

    pairings = PairingRecommendation
      .where(drink_menuitem_id: menuitem.id)
      .order(score: :desc)
      .limit(4)
      .includes(:food_menuitem)

    similar = []
    link = menuitem.menu_item_product_links.first
    if link
      similar = SimilarProductRecommendation
        .where(product_id: link.product_id)
        .order(score: :desc)
        .limit(3)
        .includes(recommended_product: :menuitems)
    end

    render json: {
      drink: { id: menuitem.id, name: menuitem.name },
      pairings: pairings.map { |p| format_pairing(p) },
      similar: similar.map { |s| format_similar(s, @menu) },
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Item not found' }, status: :not_found
  end

  private

  def set_smartmenu
    @smartmenu = Smartmenu.find_by!(slug: params[:smartmenu_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Smartmenu not found' }, status: :not_found
  end

  def set_menu
    @menu = @smartmenu.menu
    render json: { error: 'No menu' }, status: :not_found unless @menu
  end

  def format_recommendation(rec)
    item = rec[:menuitem]
    enrichment = rec[:enrichment] || {}
    tasting = enrichment['tasting_notes'] || {}

    result = {
      id: item.id,
      name: item.name,
      description: item.description,
      price: item.price,
      category: item.sommelier_category,
      tags: rec[:tags],
      score: (rec[:score] * 100).round,
    }

    if tasting.any?
      result[:tasting_notes] = tasting.slice('nose', 'palate', 'finish').compact_blank
    end

    result[:story] = enrichment['brand_story'] if enrichment['brand_story'].present?
    result[:region] = enrichment['region'] if enrichment['region'].present?

    if rec[:best_pairing]
      food = rec[:best_pairing].food_menuitem
      result[:best_pairing] = {
        food_name: food.name,
        rationale: rec[:best_pairing].rationale,
        score: rec[:best_pairing].display_score,
      }
    end

    result
  end

  def format_wine_recommendation(rec)
    result = format_recommendation(rec)
    result[:wine_color] = rec[:wine_color] if rec[:wine_color].present?
    result[:grape_variety] = rec[:grape_variety] if rec[:grape_variety].present?
    result[:appellation] = rec[:appellation] if rec[:appellation].present?
    result[:vintage_year] = rec[:vintage_year] if rec[:vintage_year].present?
    result[:classification] = rec[:classification] if rec[:classification].present?
    result
  end

  def format_pairing(pairing)
    {
      food_id: pairing.food_menuitem_id,
      food_name: pairing.food_menuitem.name,
      food_description: pairing.food_menuitem.description,
      food_price: pairing.food_menuitem.price,
      score: pairing.display_score,
      pairing_type: pairing.pairing_type,
      rationale: pairing.rationale,
    }
  end

  def format_similar(rec, menu)
    product = rec.recommended_product
    on_menu_item = product.menuitems
                          .joins(menusection: :menu)
                          .where(menus: { id: menu.id }, status: 'active')
                          .first

    {
      product_name: product.canonical_name,
      score: (rec.score.to_f * 100).round,
      rationale: rec.rationale,
      on_menu: on_menu_item.present?,
      menuitem_id: on_menu_item&.id,
      menuitem_name: on_menu_item&.name,
      menuitem_price: on_menu_item&.price,
    }
  end
end
