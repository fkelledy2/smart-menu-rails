module Madmin
  module ApplicationHelper
    def madmin_root_path
      Rails.application.routes.url_helpers.madmin_root_path
    end

    def madmin_root_url
      Rails.application.routes.url_helpers.madmin_root_path
    end

    def nav_link_to(label, path, html_options = {})
      classes = Array(html_options[:class])
      classes << 'active' if respond_to?(:current_page?) && current_page?(path)
      html_options[:class] = classes.join(' ')

      link_to(label, path, html_options)
    end
  end
end
