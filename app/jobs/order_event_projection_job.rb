class OrderEventProjectionJob < ApplicationJob
  queue_as :default

  def perform(ordr_id)
    OrderEventProjector.project!(ordr_id)
  end
end
