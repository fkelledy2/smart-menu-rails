class AddPerformanceIndexes < ActiveRecord::Migration[7.2]
  # These indexes address high-impact query patterns identified during the
  # performance audit. All additions use `if_not_exists: true` so they are
  # safe to re-run and will not fail if a concurrent deployment already added
  # them.
  def change
    # ---- restaurants --------------------------------------------------------
    # status is queried frequently (index, active-only scopes) but only a
    # *partial* index exists (archived = false).  A plain index covers all
    # status-based filters.
    add_index :restaurants, :status,
              name: 'index_restaurants_on_status',
              if_not_exists: true

    # ---- ordrs --------------------------------------------------------------
    # `orderedAt` is used in revenue_summary GROUP BY and date-range analytics
    # but has no dedicated index (the existing composite indexes put created_at
    # first, not orderedAt).
    add_index :ordrs, :orderedAt,
              name: 'index_ordrs_on_orderedAt',
              if_not_exists: true

    # ---- ordractions --------------------------------------------------------
    # ordr_id + action composite lookup used in orderedCount / orderedItems
    # methods.  A plain ordr_id index exists but the composite is missing.
    add_index :ordractions, %i[ordr_id action],
              name: 'index_ordractions_on_ordr_id_action',
              if_not_exists: true

    # ---- menuitemlocales ----------------------------------------------------
    # resolve_localised_name does two fallback queries both filtered on
    # menuitem_id + LOWER(locale).  The existing index covers exact locale
    # matches; add a functional index for the case-insensitive fallback path.
    add_index :menuitemlocales,
              'menuitem_id, LOWER(locale)',
              name: 'index_menuitemlocales_on_menuitem_lower_locale',
              if_not_exists: true

    # ---- restaurantlocales --------------------------------------------------
    # Same case-insensitive locale lookup used in resolve_localised_name /
    # getLocale.  The existing (restaurant_id, locale) index is exact-case.
    add_index :restaurantlocales,
              'restaurant_id, LOWER(locale)',
              name: 'index_restaurantlocales_on_restaurant_lower_locale',
              if_not_exists: true

    # ---- menuitems ----------------------------------------------------------
    # whiskey_ambassador_ready? queries (itemtype, status) across all items for
    # a restaurant's menus.  The existing partial index on section_status_active
    # does not cover itemtype.
    add_index :menuitems, %i[menusection_id itemtype status],
              name: 'index_menuitems_on_section_itemtype_status',
              where: '(archived = false)',
              if_not_exists: true

    # ---- ordritems ----------------------------------------------------------
    # Subquery in cached_menu_performance uses ordr_id IN (subquery) scoped to
    # a menu — the existing ordr_id index covers this, but adding a composite
    # with status helps the kitchen dashboard status filters.
    add_index :ordritems, %i[ordr_id menuitem_id],
              name: 'index_ordritems_on_ordr_id_menuitem_id',
              if_not_exists: true
  end
end
