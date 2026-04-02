class AddHnswIndexToMenuItemSearchDocuments < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!
  # Requires pgvector >= 0.5.0 (production has 0.8.0).
  # HNSW offers better recall than IVFFlat and does not require pre-training
  # data — it builds incrementally so accuracy is consistent even on small
  # datasets. Parameters: m=16 (connections per node), ef_construction=64
  # (candidates during build) are pgvector defaults and suit a 384-dim
  # all-MiniLM-L6-v2 embedding space well.
  #
  # We keep the existing IVFFlat index until it can be benchmarked and
  # confirmed redundant in production (one index is enough at query time
  # because the planner will pick the cheapest one).
  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
        idx_menu_item_search_docs_embedding_hnsw
        ON menu_item_search_documents
        USING hnsw (embedding vector_cosine_ops)
        WITH (m = 16, ef_construction = 64)
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX CONCURRENTLY IF EXISTS idx_menu_item_search_docs_embedding_hnsw
    SQL
  end
end
