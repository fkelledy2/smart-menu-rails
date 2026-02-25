# frozen_string_literal: true

namespace :pg do
  desc 'Run VACUUM ANALYZE on high-churn tables (ordrs, ordritems, ordrparticipants, etc.)'
  task vacuum_analyze: :environment do
    tables = %w[
      ordrs
      ordritems
      ordrparticipants
      ordractions
      menuparticipants
      alcohol_order_events
    ]

    conn = ActiveRecord::Base.connection

    tables.each do |table|
      puts "VACUUM ANALYZE #{table}..."
      conn.execute("VACUUM ANALYZE #{conn.quote_table_name(table)}")
      puts '  done.'
    end

    puts "\nAll tables vacuumed and analyzed."
  end

  desc 'Report table bloat and dead tuple counts for hot tables'
  task bloat_report: :environment do
    sql = <<~SQL.squish
      SELECT
        schemaname,
        relname AS table_name,
        n_live_tup AS live_tuples,
        n_dead_tup AS dead_tuples,
        CASE WHEN n_live_tup > 0
          THEN round(100.0 * n_dead_tup / n_live_tup, 1)
          ELSE 0
        END AS dead_pct,
        last_vacuum,
        last_autovacuum,
        last_analyze,
        last_autoanalyze
      FROM pg_stat_user_tables
      WHERE relname IN (
        'ordrs', 'ordritems', 'ordrparticipants', 'ordractions',
        'menuparticipants', 'menuitems', 'menusections', 'menus',
        'smartmenus', 'alcohol_order_events'
      )
      ORDER BY n_dead_tup DESC;
    SQL

    rows = ActiveRecord::Base.connection.execute(sql)

    puts 'Table                           Live       Dead    Dead%          Last Vacuum      Last Autovacuum'
    puts '-' * 100

    rows.each do |row|
      puts format('%-25s %10s %10s %7s%% %20s %20s',
                  row['table_name'],
                  row['live_tuples'],
                  row['dead_tuples'],
                  row['dead_pct'],
                  row['last_vacuum']&.to_s&.slice(0, 19) || 'never',
                  row['last_autovacuum']&.to_s&.slice(0, 19) || 'never',)
    end
  end

  desc 'Report index bloat for tables with high write volume'
  task index_bloat: :environment do
    sql = <<~SQL.squish
      SELECT
        t.tablename AS table_name,
        i.indexrelname AS index_name,
        pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
        i.idx_scan AS scans,
        i.idx_tup_read AS tuples_read,
        i.idx_tup_fetch AS tuples_fetched
      FROM pg_stat_user_indexes i
      JOIN pg_tables t ON t.tablename = i.relname
      WHERE t.tablename IN (
        'ordrs', 'ordritems', 'ordrparticipants', 'ordractions',
        'menuparticipants', 'menuitems', 'smartmenus'
      )
      ORDER BY pg_relation_size(i.indexrelid) DESC
      LIMIT 40;
    SQL

    rows = ActiveRecord::Base.connection.execute(sql)

    puts 'Table                     Index                                                    Size      Scans'
    puts '-' * 100

    rows.each do |row|
      puts format('%-25s %-50s %10s %10s',
                  row['table_name'],
                  row['index_name'],
                  row['index_size'],
                  row['scans'],)
    end
  end

  desc 'Tune autovacuum for high-churn tables (run once)'
  task tune_autovacuum: :environment do
    tables = %w[ordrs ordritems ordrparticipants ordractions menuparticipants]
    conn = ActiveRecord::Base.connection

    tables.each do |table|
      # More aggressive vacuum: trigger at 5% dead tuples instead of default 20%
      conn.execute("ALTER TABLE #{conn.quote_table_name(table)} SET (autovacuum_vacuum_scale_factor = 0.05)")
      # More aggressive analyze: trigger at 5% changed tuples instead of default 10%
      conn.execute("ALTER TABLE #{conn.quote_table_name(table)} SET (autovacuum_analyze_scale_factor = 0.05)")
      puts "Tuned autovacuum for #{table}: vacuum_scale_factor=0.05, analyze_scale_factor=0.05"
    end

    puts "\nDone. These settings persist across restarts."
  end
end
