class Plan < ApplicationRecord

  enum status: {
    inactive: 0,
    active: 1,
  }

  enum action: {
    register: 0,
    call: 1,
  }
end
