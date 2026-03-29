---
name: PerformanceAnalyticsController#export_metrics references undefined local variable timeframe_str
description: export_csv and export_json call timeframe_str (a method) but the local variable timeframe_str in export_metrics is not in scope — NameError
type: project
---

`app/controllers/performance_analytics_controller.rb` lines 187 and 195:
```ruby
send_data csv_data,
          filename: "performance_metrics_#{timeframe_str}_#{Date.current}.csv"
...
send_data summary.to_json,
          filename: "performance_summary_#{timeframe_str}_#{Date.current}.json"
```
`timeframe_str` is a private method defined at the bottom of the controller (line 199). Inside `export_csv` and `export_json`, calling `timeframe_str` should work as a method call — BUT `timeframe_str` is also the name of the local variable used in `export_metrics` (`format = params[:format] || 'json'` is `format`, not `timeframe_str`).

Actually the issue is that `timeframe_str` used in `send_data filename:` inside `export_csv`/`export_json` is calling the private method — this is fine in Ruby. However, `export_csv` and `export_json` are called from `export_metrics` with `timeframe` as a parameter, and then inside those methods `timeframe_str` re-reads `params[:timeframe]` independently. There is no bug here per se, but the method name `timeframe_str` shadowing the local `format` variable in the parent context makes the code fragile.

Wait — re-reading: `export_csv(timeframe)` and `export_json(timeframe)` receive the computed `timeframe` duration, but inside them `timeframe_str` calls `parse_timeframe(params[:timeframe] || '24h')` again — double parsing is wasteful but not a bug.

**Status:** Non-bug on further analysis — remove this memory entry if confirmed safe.
