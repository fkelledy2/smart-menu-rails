# Concern for models that support soft deletion via archived field
# Provides consistent behavior across all models with soft deletion
module SoftDeletable
  extend ActiveSupport::Concern

  included do
    # Scopes for soft deletion
    scope :active, -> { where(archived: false) }
    scope :archived, -> { where(archived: true) }
    scope :not_archived, -> { where(archived: false) }

    # Default scope to exclude archived records (optional - can be overridden)
    # scope :default, -> { active }

    # Callbacks
    before_create :set_archived_default
  end

  # Soft delete the record
  # @param archive_time [Time] Optional timestamp for when the record was archived
  # @return [Boolean] True if successfully archived
  def archive!(archive_time: Time.current)
    update!(archived: true, archived_at: archive_time)
  end

  # Restore an archived record
  # @return [Boolean] True if successfully restored
  def restore!
    update!(archived: false, archived_at: nil)
  end

  # Check if record is archived
  # @return [Boolean] True if record is archived
  def archived?
    archived == true
  end

  # Check if record is active (not archived)
  # @return [Boolean] True if record is active
  def active?
    !archived?
  end

  # Soft delete with optional reason
  # @param reason [String] Optional reason for archiving
  # @param archived_by [User] Optional user who performed the archiving
  # @return [Boolean] True if successfully archived
  def archive_with_reason!(reason: nil, archived_by: nil)
    attributes = { archived: true, archived_at: Time.current }
    attributes[:archived_reason] = reason if respond_to?(:archived_reason=) && reason.present?
    attributes[:archived_by_id] = archived_by.id if respond_to?(:archived_by_id=) && archived_by.present?

    update!(attributes)
  end

  # Get human-readable status
  # @return [String] Status as string
  def status_text
    archived? ? 'Archived' : 'Active'
  end

  class_methods do
    # Find records including archived ones
    # @return [ActiveRecord::Relation] All records including archived
    def with_archived
      unscoped
    end

    # Find only archived records
    # @return [ActiveRecord::Relation] Only archived records
    def only_archived
      unscoped.where(archived: true)
    end

    # Archive multiple records at once
    # @param ids [Array] Array of record IDs to archive
    # @param reason [String] Optional reason for archiving
    # @param archived_by [User] Optional user who performed the archiving
    # @return [Integer] Number of records archived
    def archive_all(ids, reason: nil, archived_by: nil)
      attributes = { archived: true, archived_at: Time.current }
      attributes[:archived_reason] = reason if column_names.include?('archived_reason') && reason.present?
      attributes[:archived_by_id] = archived_by.id if column_names.include?('archived_by_id') && archived_by.present?

      where(id: ids).update_all(attributes)
    end

    # Restore multiple records at once
    # @param ids [Array] Array of record IDs to restore
    # @return [Integer] Number of records restored
    def restore_all(ids)
      attributes = { archived: false, archived_at: nil }
      attributes[:archived_reason] = nil if column_names.include?('archived_reason')
      attributes[:archived_by_id] = nil if column_names.include?('archived_by_id')

      where(id: ids).update_all(attributes)
    end

    # Permanently delete archived records older than specified time
    # @param older_than [ActiveSupport::Duration] Time threshold (e.g., 1.year.ago)
    # @return [Integer] Number of records permanently deleted
    def purge_archived(older_than: 1.year.ago)
      only_archived.where(archived_at: ...older_than).delete_all
    end
  end

  private

  def set_archived_default
    self.archived = false if archived.nil?
  end
end
