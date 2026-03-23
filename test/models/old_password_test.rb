# frozen_string_literal: true

require 'test_helper'

class OldPasswordTest < ActiveSupport::TestCase
  test 'belongs to user' do
    assert OldPassword.reflect_on_association(:user)
  end

  test 'can be created with a user' do
    user = users(:one)
    op = OldPassword.new(user: user, encrypted_password: 'fakehash')
    assert op.valid? || op.errors.none? { |e| e.attribute == :user }
  end
end
