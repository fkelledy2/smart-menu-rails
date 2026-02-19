# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = 'https://www.mellow.menu'
SitemapGenerator::Sitemap.create do
  # Static pages
  add '/', priority: 1.0, changefreq: 'daily'
  add '/terms', priority: 0.3, changefreq: 'monthly'
  add '/privacy', priority: 0.3, changefreq: 'monthly'

  # All published smartmenus (public menu pages)
  Smartmenu.includes(:restaurant, :menu)
    .joins(:restaurant)
    .where(tablesetting_id: nil)
    .where(restaurants: { preview_enabled: true })
    .find_each do |sm|
    add "/smartmenus/#{sm.slug}",
        lastmod: [sm.updated_at, sm.menu&.updated_at, sm.restaurant&.updated_at].compact.max,
        changefreq: 'weekly',
        priority: 0.8
  end

  # Explore pages
  ExplorePage.published.find_each do |page|
    add page.path, lastmod: page.updated_at, changefreq: 'weekly', priority: 0.7
  end

  # Local guides
  LocalGuide.published.find_each do |guide|
    add "/guides/#{guide.slug}", lastmod: guide.updated_at, changefreq: 'weekly', priority: 0.6
  end
end
