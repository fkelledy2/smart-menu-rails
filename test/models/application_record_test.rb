require 'test_helper'

class ApplicationRecordTest < ActiveSupport::TestCase
  test 'is abstract class' do
    assert ApplicationRecord.abstract_class?
  end

  test 'is primary abstract class' do
    assert_respond_to ApplicationRecord, :primary_abstract_class
  end

  test 'has database connection configuration' do
    assert_respond_to ApplicationRecord, :connects_to
  end

  test 'has on_replica class method' do
    assert_respond_to ApplicationRecord, :on_replica
  end

  test 'has on_primary class method' do
    assert_respond_to ApplicationRecord, :on_primary
  end

  test 'has using_replica? class method' do
    assert_respond_to ApplicationRecord, :using_replica?
  end

  test 'using_replica? returns boolean' do
    result = ApplicationRecord.using_replica?
    assert [true, false].include?(result)
  end

  test 'on_primary executes block' do
    executed = false
    ApplicationRecord.on_primary do
      executed = true
    end
    assert executed
  end

  test 'on_replica executes block with fallback' do
    executed = false
    ApplicationRecord.on_replica do
      executed = true
    end
    assert executed
  end
end
