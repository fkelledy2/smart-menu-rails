---
name: FeaturesPlan N+1 in homepage
description: home/index.html.erb runs FeaturesPlan.where per plan+feature in a nested loop; preloaded in controller with group_by
type: project
---

`app/views/home/index.html.erb` contained a nested loop (`@features.each` / `@plans.each`) with `FeaturesPlan.where(plan_id: plan.id, feature_id: feature.id).first` inside — O(plans * features) queries per page load.

The table is hidden (`d-none`) so it has no visual impact, but the queries still execute on every anonymous homepage hit.

**Fix:** In `HomeController#index`, preload: `@features_plans = FeaturesPlan.all.group_by { |fp| [fp.plan_id, fp.feature_id] }`. In the view, replace the `where` call with `@features_plans[[plan.id, feature.id]].present?`.

**How to apply:** Any view loop calling an AR query inside an iteration over a second collection is an N+1. Preload with `group_by` in the controller.
