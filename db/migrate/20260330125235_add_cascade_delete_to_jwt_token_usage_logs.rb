class AddCascadeDeleteToJwtTokenUsageLogs < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :jwt_token_usage_logs, :admin_jwt_tokens
    add_foreign_key :jwt_token_usage_logs, :admin_jwt_tokens, column: :jwt_token_id, on_delete: :cascade
  end
end
