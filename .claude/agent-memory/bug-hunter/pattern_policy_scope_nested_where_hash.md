---
name: Pundit Scope uses invalid nested WHERE hash for deep joins
description: OrdritemnotePolicy::Scope used .where(ordritems: { ordrs: {...} }) — AR only supports one level of table nesting; generates invalid SQL (FIXED)
type: project
---

`app/policies/ordritemnote_policy.rb` Scope#resolve:

```ruby
# BEFORE (broken): AR interprets 'ordrs' as a column on ordritems, not a joined table
scope.joins(ordritem: { ordr: :restaurant })
  .where(ordritems: { ordrs: { restaurant_id: restaurant_ids } })

# AFTER (fixed): reference the joined ordrs table directly
scope.joins(ordritem: { ordr: :restaurant })
  .where(ordrs: { restaurant_id: restaurant_ids })
```

ActiveRecord's hash-based `where` supports exactly ONE level of `{ table: { column: value } }`. Going two levels deep (`{ table1: { table2: { column: value } } }`) does not work as a nested table condition — AR treats `table2` as a column name on `table1`, generating invalid SQL like `WHERE "ordritems"."ordrs" IN (...)`.

The scope test only tested the nil-user path (returns `scope.none`), so the authenticated-user path was unexercised and the SQL bug was invisible until runtime.

**Why:** Developer assumed Rails would traverse the join chain in the WHERE hash the same way it does for `includes`/`joins`. It does not.

**How to apply:** After deep joins, always write WHERE conditions using the **final joined table name directly**: `.where(ordrs: { restaurant_id: ... })`, not `.where(ordritems: { ordrs: { ... } })`. Write a scope test that actually exercises the authenticated path to catch SQL errors.
