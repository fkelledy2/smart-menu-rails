class CreateToolInvocationLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :tool_invocation_logs do |t|
      t.references :agent_workflow_step, null: false, foreign_key: true, index: true
      t.string :tool_name, null: false
      t.jsonb :input_params, null: false, default: {}
      t.jsonb :output_payload, null: false, default: {}
      t.string :status, null: false, default: 'success'
      t.integer :duration_ms
      t.datetime :invoked_at, null: false

      t.timestamps
    end

    add_index :tool_invocation_logs, :tool_name
    add_index :tool_invocation_logs, :status
    add_index :tool_invocation_logs, :invoked_at

    add_check_constraint :tool_invocation_logs,
      "status IN ('success','error','timeout')",
      name: 'tool_invocation_logs_status_check'
  end
end
