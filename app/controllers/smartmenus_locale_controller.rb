class SmartmenusLocaleController < ApplicationController
  # PATCH /smartmenus/:smartmenu_id/locale
  def update
    @smartmenu = Smartmenu.where(slug: params[:smartmenu_id]).includes(
      menu: [
        { restaurant: :restaurantlocales },
        :menulocales,
        { menusections: [
            :menusectionlocales,
            { menuitems: [:menuitemlocales, :tags, :sizes, :ingredients, :allergyns, :genimage, :inventory] },
            :genimage
          ] },
        :menuavailabilities,
        :genimage
      ]
    ).first

    locale = params[:locale]
    # Render all menuitems as partials and return a hash of dom_id => html
    menuitems = @smartmenu.menu.menuitems
    html_updates = menuitems.map do |mi|
      [view_context.dom_id(mi), render_to_string(partial: "smartmenus/showMenuitemHorizontal", locals: { mi: mi, ordrparticipant: OpenStruct.new(preferredlocale: locale), menuparticipant: nil, menu: @smartmenu.menu })]
    end.to_h

    # Broadcast via ActionCable (OrdrChannel)
    ActionCable.server.broadcast("ordr_#{params[:order_id]}_channel", { menuitem_updates: html_updates })

    head :ok
  end
end
