---
name: testimonials/show.html.erb nil dereference on user/restaurant
description: show.html.erb called @testimonial.user.name and .restaurant.name without nil guards — NoMethodError if association missing (FIXED)
type: project
---

testimonials/show.html.erb accessed `@testimonial.user.name` and `@testimonial.restaurant.name` without safe navigation. While belongs_to is mandatory by default, cached data via IdentityCache can return nil if the associated record was deleted without invalidating the cache.

Fix: use `@testimonial.user&.name` and `@testimonial.restaurant&.name`.

**Why:** Testimonial uses IdentityCache with cache_belongs_to; a stale cache entry can return nil for the association even when the DB record has been deleted.

**How to apply:** Any view accessing a cached association should use safe navigation.
