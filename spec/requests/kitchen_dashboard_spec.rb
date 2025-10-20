require 'rails_helper'

RSpec.describe "KitchenDashboards", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/kitchen_dashboard/index"
      expect(response).to have_http_status(:success)
    end
  end

end
