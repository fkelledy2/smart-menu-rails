# frozen_string_literal: true

require 'test_helper'

class GuidesControllerTest < ActionDispatch::IntegrationTest
  test 'GET index succeeds anonymously' do
    get guides_path
    assert_response :success
  end

  test 'GET show returns 404 for unknown slug' do
    get guide_path(slug: 'no-such-guide-xyz')
    assert_response :not_found
  end
end
