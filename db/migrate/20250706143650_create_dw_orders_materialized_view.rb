class CreateDwOrdersMaterializedView < ActiveRecord::Migration[7.1]
  def up
    execute <<-SQL
      CREATE MATERIALIZED VIEW dw_orders_mv AS
      SELECT
        o.id AS order_id,
        o."orderedAt" AS ordered_at,
        o."paidAt" AS paid_at,
        ROUND(o.nett::NUMERIC, 2) AS nett_amount,
        ROUND(o.gross::NUMERIC, 2) AS gross_amount,
        ROUND(o.tax::NUMERIC, 2) AS tax_amount,
        ROUND(o.tip::NUMERIC, 2) AS tip_amount,
        ROUND(o.covercharge::NUMERIC, 2) AS covercharge_amount,
        o.status,

        r.id AS restaurant_id,
        r.name AS restaurant_name,
        r.city,
        r.country,
        r.currency,

        m.id AS menu_id,
        m.name AS menu_name,

        e.id AS employee_id,
        e.role,

        t.id AS tablesetting_id,
        t.name AS table_name,
        t.capacity AS table_capacity,
        t."tabletype" AS table_type

      FROM ordrs o
      JOIN restaurants r ON o.restaurant_id = r.id
      JOIN menus m ON o.menu_id = m.id
      JOIN employees e ON o.employee_id = e.id
      JOIN tablesettings t ON o.tablesetting_id = t.id
      JOIN ordritems oi ON oi.ordr_id = o.id
      JOIN menuitems mi ON oi.menuitem_id = mi.id
      JOIN menusections ms ON mi.menusection_id = ms.id

      GROUP BY
        o.id, o."orderedAt", o."deliveredAt", o."paidAt", o.nett, o.gross, o.tax, o.tip, o.covercharge, o.status,
        r.id, r.name, r.city, r.country, r.currency,
        m.id, m.name,
        e.id, e.role,
        t.id, t.name, t.capacity, t."tabletype"
      ORDER BY
        o.id desc;
    SQL
  end

  def down
    execute <<-SQL
      DROP MATERIALIZED VIEW IF EXISTS dw_orders_mv;
    SQL
  end
end
