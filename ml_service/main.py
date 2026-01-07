import os
import time
from typing import Any, Dict, List, Optional

import numpy as np
from cachetools import TTLCache
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

try:
    from sentence_transformers import SentenceTransformer, CrossEncoder
except Exception as e:  # pragma: no cover
    SentenceTransformer = None
    CrossEncoder = None
    _SENTENCE_TRANSFORMERS_IMPORT_ERROR = repr(e)


APP_NAME = "smart-menu-ml"

DEFAULT_EMBED_MODEL = os.getenv("EMBED_MODEL", "intfloat/multilingual-e5-small")
DEFAULT_RERANK_MODEL = os.getenv("RERANK_MODEL", "cross-encoder/ms-marco-MiniLM-L-6-v2")

RERANK_ENABLED = os.getenv("RERANK_ENABLED", "1").strip().lower() not in {"0", "false", "no"}
EAGER_LOAD_RERANKER = os.getenv("EAGER_LOAD_RERANKER", "0").strip().lower() in {"1", "true", "yes"}

# Keep small caches to reduce tail latency.
EMBED_CACHE_TTL_SECONDS = int(os.getenv("EMBED_CACHE_TTL_SECONDS", "900"))
EMBED_CACHE_MAX_ITEMS = int(os.getenv("EMBED_CACHE_MAX_ITEMS", "4096"))
RERANK_CACHE_TTL_SECONDS = int(os.getenv("RERANK_CACHE_TTL_SECONDS", "300"))
RERANK_CACHE_MAX_ITEMS = int(os.getenv("RERANK_CACHE_MAX_ITEMS", "2048"))


class HealthResponse(BaseModel):
    ok: bool
    app: str
    embed_model: str
    rerank_model: str


class EmbedRequest(BaseModel):
    texts: List[str] = Field(min_length=1)
    locale: Optional[str] = None


class EmbedResponse(BaseModel):
    vectors: List[List[float]]
    model: str


class RerankCandidate(BaseModel):
    id: str
    text: str


class RerankRequest(BaseModel):
    query: str
    candidates: List[RerankCandidate] = Field(min_length=1)
    locale: Optional[str] = None


class RerankItem(BaseModel):
    id: str
    score: float


class RerankResponse(BaseModel):
    ranked: List[RerankItem]
    model: str


app = FastAPI(title=APP_NAME)

_embed_cache: TTLCache = TTLCache(maxsize=EMBED_CACHE_MAX_ITEMS, ttl=EMBED_CACHE_TTL_SECONDS)
_rerank_cache: TTLCache = TTLCache(maxsize=RERANK_CACHE_MAX_ITEMS, ttl=RERANK_CACHE_TTL_SECONDS)

_embedder = None
_reranker = None


def _norm_locale(raw: Optional[str]) -> str:
    s = (raw or "").strip().lower().replace("_", "-")
    base = (s.split("-")[0] if s else "").strip()
    return base or "en"


def _cache_key_embed(text: str, locale: Optional[str]) -> str:
    loc = _norm_locale(locale)
    return f"{loc}::v1::{text.strip().lower()}"


def _cache_key_rerank(query: str, candidates: List[RerankCandidate], locale: Optional[str]) -> str:
    loc = _norm_locale(locale)
    ids = ",".join([c.id for c in candidates])
    return f"{loc}::v1::{query.strip().lower()}::{ids}"


def _load_models() -> None:
    global _embedder, _reranker

    if SentenceTransformer is None:
        import_err = globals().get("_SENTENCE_TRANSFORMERS_IMPORT_ERROR")
        if import_err:
            raise RuntimeError(f"sentence-transformers not available: {import_err}")
        raise RuntimeError("sentence-transformers not available")

    # NOTE: we keep a single process per dyno to avoid loading models multiple times.
    _embedder = SentenceTransformer(DEFAULT_EMBED_MODEL)

    _reranker = None
    if RERANK_ENABLED and EAGER_LOAD_RERANKER and CrossEncoder is not None:
        try:
            _reranker = CrossEncoder(DEFAULT_RERANK_MODEL)
        except Exception:
            _reranker = None


def _ensure_reranker_loaded() -> None:
    global _reranker

    if _reranker is not None:
        return

    if not RERANK_ENABLED:
        return

    if CrossEncoder is None:
        return

    try:
        _reranker = CrossEncoder(DEFAULT_RERANK_MODEL)
    except Exception:
        _reranker = None


@app.on_event("startup")
def _startup() -> None:
    _load_models()


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(
        ok=True,
        app=APP_NAME,
        embed_model=DEFAULT_EMBED_MODEL,
        rerank_model=DEFAULT_RERANK_MODEL if _reranker is not None else "(disabled)",
    )


@app.post("/embed", response_model=EmbedResponse)
def embed(req: EmbedRequest) -> EmbedResponse:
    if _embedder is None:
        raise HTTPException(status_code=503, detail="Embedder not ready")

    out: List[List[float]] = []
    missing_texts: List[str] = []
    missing_idx: List[int] = []

    for i, t in enumerate(req.texts):
        key = _cache_key_embed(t, req.locale)
        v = _embed_cache.get(key)
        if v is None:
            out.append([])
            missing_texts.append(t)
            missing_idx.append(i)
        else:
            out.append(v)

    if missing_texts:
        # SentenceTransformer returns np.ndarray
        vecs = _embedder.encode(missing_texts, normalize_embeddings=True)
        if isinstance(vecs, list):
            vecs = np.array(vecs, dtype=np.float32)

        for j, idx in enumerate(missing_idx):
            v = vecs[j].astype(np.float32).tolist()
            out[idx] = v
            _embed_cache[_cache_key_embed(req.texts[idx], req.locale)] = v

    return EmbedResponse(vectors=out, model=DEFAULT_EMBED_MODEL)


@app.post("/rerank", response_model=RerankResponse)
def rerank(req: RerankRequest) -> RerankResponse:
    if _embedder is None:
        raise HTTPException(status_code=503, detail="Models not ready")

    # Cache by query + candidate ids (not candidate text; assumes stable docs in DB).
    cache_key = _cache_key_rerank(req.query, req.candidates, req.locale)
    cached = _rerank_cache.get(cache_key)
    if cached is not None:
        return RerankResponse(ranked=[RerankItem(**x) for x in cached], model=DEFAULT_RERANK_MODEL)

    q = req.query.strip()
    if not q:
        raise HTTPException(status_code=422, detail="Query cannot be empty")

    ranked: List[Dict[str, Any]] = []

    t0 = time.time()
    if RERANK_ENABLED:
        _ensure_reranker_loaded()

    if _reranker is not None:
        pairs = [[q, c.text] for c in req.candidates]
        scores = _reranker.predict(pairs)
        if isinstance(scores, list):
            scores = np.array(scores, dtype=np.float32)
        for c, s in zip(req.candidates, scores.tolist()):
            ranked.append({"id": c.id, "score": float(s)})
    else:
        # Fallback: cosine similarity between query embedding and candidate embedding (derived from text).
        # This is slower than a true reranker but keeps the service functional if the reranker model
        # is unavailable.
        qv = _embedder.encode([q], normalize_embeddings=True)[0]
        cv = _embedder.encode([c.text for c in req.candidates], normalize_embeddings=True)
        sims = (cv @ qv).astype(np.float32)
        for c, s in zip(req.candidates, sims.tolist()):
            ranked.append({"id": c.id, "score": float(s)})

    ranked.sort(key=lambda x: x["score"], reverse=True)

    # Store compact cache payload
    _rerank_cache[cache_key] = ranked

    _ = time.time() - t0
    return RerankResponse(ranked=[RerankItem(**x) for x in ranked], model=DEFAULT_RERANK_MODEL if _reranker is not None else "(fallback)")
