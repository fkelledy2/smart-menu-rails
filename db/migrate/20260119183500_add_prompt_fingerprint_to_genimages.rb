class AddPromptFingerprintToGenimages < ActiveRecord::Migration[7.1]
  def change
    add_column :genimages, :prompt_fingerprint, :string
    add_index :genimages, :prompt_fingerprint
  end
end
