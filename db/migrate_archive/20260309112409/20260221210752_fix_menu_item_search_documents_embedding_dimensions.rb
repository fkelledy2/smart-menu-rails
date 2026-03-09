class FixMenuItemSearchDocumentsEmbeddingDimensions < ActiveRecord::Migration[7.2]
  def up
    # The ML service returns 384-dimensional vectors, but the column was created as vector(1024).
    # Drop the ivfflat index, alter the column, then recreate the index.
    execute <<~SQL
      DROP INDEX IF EXISTS idx_menu_item_search_docs_embedding_ivfflat;
    SQL

    execute <<~SQL
      ALTER TABLE menu_item_search_documents
      ALTER COLUMN embedding TYPE vector(384)
      USING NULL;
    SQL

    # Clear stale embeddings so they are regenerated with correct dimensions
    execute <<~SQL
      UPDATE menu_item_search_documents SET embedding = NULL;
    SQL

    # Delete all rows so the job re-indexes with correct dimensions
    execute <<~SQL
      DELETE FROM menu_item_search_documents;
    SQL

    execute <<~SQL
      CREATE INDEX idx_menu_item_search_docs_embedding_ivfflat
      ON menu_item_search_documents
      USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 50);
    SQL
  rescue StandardError => e
    Rails.logger.warn("[Migration] Could not alter embedding column: #{e.message}")
  end

  def down
    execute <<~SQL
      DROP INDEX IF EXISTS idx_menu_item_search_docs_embedding_ivfflat;
    SQL

    execute <<~SQL
      ALTER TABLE menu_item_search_documents
      ALTER COLUMN embedding TYPE vector(1024)
      USING NULL;
    SQL

    execute <<~SQL
      DELETE FROM menu_item_search_documents;
    SQL

    execute <<~SQL
      CREATE INDEX idx_menu_item_search_docs_embedding_ivfflat
      ON menu_item_search_documents
      USING ivfflat (embedding vector_cosine_ops)
      WITH (lists = 50);
    SQL
  rescue StandardError => e
    Rails.logger.warn("[Migration] Could not revert embedding column: #{e.message}")
  end
end
