# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://www.mellow.menu"
SitemapGenerator::Sitemap.create do
  add '/', priority: 1.0, changefreq: 'daily'
  add '/terms', priority: 0.8, changefreq: 'monthly'
  add '/privacy', priority: 0.5, changefreq: 'monthly'

  # Add dynamic routes
  Smartmenu.find_each do |smartmenu|
    add smartmenu_path(smartmenu.slug), lastmod: smartmenu.updated_at
  end
end
