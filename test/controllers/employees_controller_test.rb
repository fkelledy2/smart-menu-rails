require 'test_helper'

class EmployeesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @employee = employees(:one)
    @user = users(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_employees_url(@restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_employee_url(@restaurant)
    assert_response :success
  end

  #   test "should create employee" do
  #     assert_difference("Employee.count") do
  #       post employees_url, params: { employee: { role: @employee.role, user_id: @employee.user.id, eid: @employee.eid, image: @employee.image, name: @employee.name, restaurant_id: @employee.restaurant_id, status: @employee.status } }
  #     end
  #     assert_redirected_to edit_restaurant_url(@employee.restaurant)
  #   end

  test 'should show employee' do
    get restaurant_employee_url(@restaurant, @employee)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_employee_url(@restaurant, @employee)
    assert_response :success
  end

  test 'should update employee' do
    patch restaurant_employee_url(@restaurant, @employee),
          params: { employee: { eid: @employee.eid, image: @employee.image, name: @employee.name,
                                restaurant_id: @employee.restaurant_id, role: @employee.role, status: @employee.status, user_id: @employee.user.id, } }
    assert_response :success
  end

  test 'should destroy employee' do
    assert_difference('Employee.count', 0) do
      delete restaurant_employee_url(@restaurant, @employee)
    end
    assert_response :success
  end
end
