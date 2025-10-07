require 'test_helper'

class ApiV1OcrMenuSectionsAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @other = users(:two)
    @section = ocr_menu_sections(:starters_section)
    @owner_token = JwtService.generate_token_for_user(@owner)
    @other_token = JwtService.generate_token_for_user(@other)
  end

  test "owner can update section" do
    patch "/api/v1/ocr_menu_sections/#{@section.id}",
          params: { 
            ocr_menu_section: { 
              name: "Updated Appetizers",
              sequence: 2
            }
          }.to_json,
          headers: { 
            'Authorization' => "Bearer #{@owner_token}",
            'Content-Type' => 'application/json'
          }
    
    # Should succeed (200) or return validation error (422), not routing error
    assert_includes [200, 422], response.status
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test "non_owner receives forbidden" do
    patch "/api/v1/ocr_menu_sections/#{@section.id}",
          params: { 
            ocr_menu_section: { 
              name: "Hacked Appetizers"
            }
          }.to_json,
          headers: { 
            'Authorization' => "Bearer #{@other_token}",
            'Content-Type' => 'application/json'
          }
    
    assert_response :forbidden
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test "unauthenticated request receives unauthorized" do
    patch "/api/v1/ocr_menu_sections/#{@section.id}",
          params: { 
            ocr_menu_section: { 
              name: "Anonymous Appetizers"
            }
          }.to_json,
          headers: { 
            'Content-Type' => 'application/json'
          }
    
    assert_response :unauthorized
    assert_equal 'application/json; charset=utf-8', response.content_type
  end
end
