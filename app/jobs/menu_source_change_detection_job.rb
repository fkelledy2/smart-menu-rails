require 'digest'

class MenuSourceChangeDetectionJob < ApplicationJob
  queue_as :default

  def perform(menu_source_id: nil, limit: 200)
    scope = MenuSource.where(status: MenuSource.statuses[:active])
    scope = scope.where(id: menu_source_id) if menu_source_id.present?

    scope = scope.order(last_checked_at: :asc, id: :asc).limit(limit.to_i)

    scope.find_each do |menu_source|
      MenuSourceChangeDetector.new(menu_source: menu_source).call
    end
  end
end
