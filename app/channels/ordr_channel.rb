class OrdrChannel < ApplicationCable::Channel
  def subscribed
    order_id = params[:order_id].presence
    slug     = params[:slug].presence
    identifier = order_id || slug
    return reject if identifier.blank?
    return reject unless authorized?(order_id: order_id, slug: slug)

    stream_from "ordr_#{identifier}_channel"
  end

  def unsubscribed; end

  private

  def authorized?(order_id:, slug:)
    # Authenticated staff always allowed — Pundit scoping applies at the
    # controller level; channel auth only needs to verify restaurant membership.
    return true if current_user

    # When qr_security_v1 is disabled the dining session gate is not enforced
    # platform-wide, so preserve the existing open-access behaviour.
    return true unless Flipper.enabled?(:qr_security_v1)

    ds = current_dining_session
    return false unless ds

    if order_id
      ordr = Ordr.select(:restaurant_id, :tablesetting_id).find_by(id: order_id)
      return false unless ordr

      ds.restaurant_id == ordr.restaurant_id &&
        ds.tablesetting_id == ordr.tablesetting_id
    elsif slug
      ds.smartmenu.slug == slug
    else
      false
    end
  end
end
