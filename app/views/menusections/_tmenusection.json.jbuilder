  json.id menusection.id
  json.name menusection.name
  json.description menusection.description
  json.image menusection.image
  json.status menusection.status
  json.sequence menusection.sequence
  json.menuitems menusection.menuitems do |menuitem|
    json.partial! 'menuitems/tmenuitem', menuitem: menuitem
  end
  json.created_at menusection.created_at
  json.updated_at menusection.updated_at
