require 'test_helper'

class EmployeesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @employee = employees(:one)
    @user = users(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get employees_url
    assert_response :success
  end

  test 'should get new' do
    get new_employee_url, params: { restaurant_id: @restaurant.id }
    assert_response :success
  end

  #   test "should create employee" do
  #     assert_difference("Employee.count") do
  #       post employees_url, params: { employee: { role: @employee.role, user_id: @employee.user.id, eid: @employee.eid, image: @employee.image, name: @employee.name, restaurant_id: @employee.restaurant_id, status: @employee.status } }
  #     end
  #     assert_redirected_to edit_restaurant_url(@employee.restaurant)
  #   end

  test 'should show employee' do
    get employee_url(@employee)
    assert_response :success
  end

  test 'should get edit' do
    get edit_employee_url(@employee)
    assert_response :success
  end

  test 'should update employee' do
    patch employee_url(@employee),
          params: { employee: { eid: @employee.eid, image: @employee.image, name: @employee.name,
                                restaurant_id: @employee.restaurant_id, status: @employee.status, } }
    #     assert_redirected_to edit_restaurant_url(@employee.restaurant)
  end

  test 'should destroy employee' do
    assert_difference('Employee.count', 0) do
      delete employee_url(@employee)
    end
    #     assert_redirected_to edit_restaurant_url(@employee.restaurant)
  end
end
