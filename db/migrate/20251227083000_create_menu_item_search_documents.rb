class CreateMenuItemSearchDocuments < ActiveRecord::Migration[7.1]
  def change
    vector_enabled = false
    begin
      enable_extension 'vector' unless extension_enabled?('vector')
      vector_enabled = extension_enabled?('vector')
    rescue StandardError
      vector_enabled = false
    end

    create_table :menu_item_search_documents do |t|
      t.bigint :restaurant_id, null: false
      t.bigint :menu_id, null: false
      t.bigint :menuitem_id, null: false
      t.string :locale, null: false

      t.text :document_text, null: false, default: ''
      t.string :content_hash, null: false
      t.datetime :indexed_at

      if vector_enabled
        t.column :embedding, 'vector(1024)'
      else
        t.text :embedding
      end

      t.timestamps
    end

    add_index :menu_item_search_documents, [:menu_id, :locale]
    add_index :menu_item_search_documents, [:menu_id, :menuitem_id, :locale], unique: true, name: 'idx_menu_item_search_docs_unique'
    add_index :menu_item_search_documents, :restaurant_id

    execute <<~SQL
      ALTER TABLE menu_item_search_documents
      ADD COLUMN document_tsv tsvector
      GENERATED ALWAYS AS (to_tsvector('simple', coalesce(document_text, ''))) STORED;
    SQL

    execute <<~SQL
      CREATE INDEX idx_menu_item_search_docs_tsv
      ON menu_item_search_documents
      USING gin (document_tsv);
    SQL

    if vector_enabled
      execute <<~SQL
        CREATE INDEX idx_menu_item_search_docs_embedding_ivfflat
        ON menu_item_search_documents
        USING ivfflat (embedding vector_cosine_ops)
        WITH (lists = 50);
      SQL
    end
  end
end
