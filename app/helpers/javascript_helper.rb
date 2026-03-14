module JavascriptHelper
  def smartmenu_javascript_tags
    if controller_name == 'smartmenus' && action_name == 'show' && !current_user
      javascript_importmap_tags('smartmenu_customer')
    else
      javascript_importmap_tags
    end
  end
end
