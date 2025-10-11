require 'test_helper'

class EmployeeTest < ActiveSupport::TestCase
  def setup
    @employee = employees(:one)
    @user = users(:one)
    @restaurant = restaurants(:one)
  end

  # === VALIDATION TESTS ===
  
  test "should be valid with valid attributes" do
    assert @employee.valid?
  end

  test "should require name" do
    @employee.name = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:name], "can't be blank"
  end

  test "should require eid" do
    @employee.eid = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:eid], "can't be blank"
  end

  test "should require role" do
    @employee.role = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:role], "can't be blank"
  end

  test "should require status" do
    @employee.status = nil
    assert_not @employee.valid?
    assert_includes @employee.errors[:status], "can't be blank"
  end

  # === ASSOCIATION TESTS ===
  
  test "should belong to user" do
    assert_respond_to @employee, :user
    assert_instance_of User, @employee.user
  end

  test "should belong to restaurant" do
    assert_respond_to @employee, :restaurant
    assert_instance_of Restaurant, @employee.restaurant
  end

  test "should have many ordrs" do
    assert_respond_to @employee, :ordrs
  end

  # === ENUM TESTS ===
  
  test "should have correct status enum values" do
    assert_equal 0, Employee.statuses[:inactive]
    assert_equal 1, Employee.statuses[:active]
    assert_equal 2, Employee.statuses[:archived]
  end

  test "should have correct role enum values" do
    assert_equal 0, Employee.roles[:staff]
    assert_equal 1, Employee.roles[:manager]
    assert_equal 2, Employee.roles[:admin]
  end

  test "should allow status changes" do
    @employee.active!
    assert @employee.active?
    
    @employee.archived!
    assert @employee.archived?
    
    @employee.inactive!
    assert @employee.inactive?
  end

  test "should allow role changes" do
    @employee.staff!
    assert @employee.staff?
    
    @employee.manager!
    assert @employee.manager?
    
    @employee.admin!
    assert @employee.admin?
  end

  # === FACTORY/CREATION TESTS ===
  
  test "should create employee with valid data" do
    employee = Employee.new(
      name: "John Doe",
      eid: "EMP001",
      role: :staff,
      status: :active,
      user: @user,
      restaurant: @restaurant
    )
    assert employee.save
    assert_equal "John Doe", employee.name
    assert_equal "EMP001", employee.eid
    assert employee.staff?
    assert employee.active?
  end

  test "should create manager employee" do
    employee = Employee.new(
      name: "Jane Manager",
      eid: "MGR001",
      role: :manager,
      status: :active,
      user: @user,
      restaurant: @restaurant
    )
    assert employee.save
    assert employee.manager?
  end

  test "should create admin employee" do
    employee = Employee.new(
      name: "Admin User",
      eid: "ADM001",
      role: :admin,
      status: :active,
      user: @user,
      restaurant: @restaurant
    )
    assert employee.save
    assert employee.admin?
  end

  # === DEPENDENT DESTROY TESTS ===
  
  test "should have correct dependent destroy configuration" do
    reflection = Employee.reflect_on_association(:ordrs)
    assert_equal :destroy, reflection.options[:dependent]
  end

  # === IDENTITY CACHE TESTS ===
  
  test "should have identity cache configured" do
    assert Employee.respond_to?(:cache_index)
  end
end
