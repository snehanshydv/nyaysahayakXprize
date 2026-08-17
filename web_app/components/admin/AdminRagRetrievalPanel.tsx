"use client";

import { useCallback, useEffect, useState } from "react";
import { AdminTabPage } from "@/components/admin/AdminPageLayout";
import {
  AdminErrorBanner,
  AdminFieldLabel,
  AdminHoverHint,
  AdminLoading,
  adminBtnPrimary,
  adminBtnSecondary,
  adminCard,
  adminInput,
} from "@/components/admin/admin-ui";
import { adminApi, type RagRetrievalConfig, type RagRetrievalSnapshot } from "@/lib/adminApi";
import { cn } from "@/lib/utils";

type GraphDraft = {
  top_k: string;
  min_similarity: string;
};

function draftsFromConfig(config: RagRetrievalConfig): Record<string, GraphDraft> {
  const out: Record<string, GraphDraft> = {};
  for (const [gid, settings] of Object.entries(config || {})) {
    out[gid] = {
      top_k: String(settings?.top_k ?? ""),
      min_similarity: String(settings?.min_similarity ?? 0),
    };
  }
  return out;
}

export function AdminRagRetrievalPanel() {
  const [snap, setSnap] = useState<RagRetrievalSnapshot | null>(null);
  const [drafts, setDrafts] = useState<Record<string, GraphDraft>>({});
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const load = useCallback(async () => {
    setError(null);
    const res = await adminApi.ragRetrievalConfig();
    setSnap(res);
    setDrafts(draftsFromConfig(res.config));
  }, []);

  useEffect(() => {
    void load().catch((err) =>
      setError(err instanceof Error ? err.message : "Failed to load RAG retrieval settings")
    );
  }, [load]);

  async function saveAll() {
    if (!snap) return;
    setLoading(true);
    setError(null);
    setMessage(null);
    try {
      const body: RagRetrievalConfig = {};
      for (const graph of snap.graphs) {
        const d = drafts[graph.id] || { top_k: "10", min_similarity: "0" };
        body[graph.id] = {
          top_k: Number(d.top_k),
          min_similarity: Number(d.min_similarity),
        };
      }
      const res = await adminApi.patchRagRetrievalConfig(body);
      setSnap((prev) =>
        prev
          ? { ...prev, config: res.config }
          : {
              config: res.config,
              defaults: res.config,
              graphs: Object.keys(res.config).map((id) => ({ id, label: id })),
              limits: { top_k_min: 1, top_k_max: 30 },
            }
      );
      setDrafts(draftsFromConfig(res.config));
      setMessage("RAG retrieval thresholds saved. Next chat/clash retrieve uses these values.");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Save failed");
    } finally {
      setLoading(false);
    }
  }

  if (!snap) {
    return (
      <AdminTabPage
        badge="Configuration"
        title="RAG retrieval"
        description="Loading…"
      >
        {error && <AdminErrorBanner message={error} onDismiss={() => setError(null)} />}
        <AdminLoading label="Loading retrieval thresholds…" />
      </AdminTabPage>
    );
  }

  const { limits } = snap;

  return (
    <AdminTabPage
      badge="Configuration"
      title="RAG retrieval thresholds"
      description="Per-graph top_k and minimum similarity for legal_documents retrieval. Separate from RAG funnel ingest."
      actions={
        <div className="flex gap-2">
          <button
            type="button"
            className={adminBtnSecondary}
            onClick={() => void load()}
            disabled={loading}
          >
            Refresh
          </button>
          <button
            type="button"
            className={adminBtnPrimary}
            onClick={() => void saveAll()}
            disabled={loading}
          >
            {loading ? "Saving…" : "Save all"}
          </button>
        </div>
      }
    >
      {error && <AdminErrorBanner message={error} onDismiss={() => setError(null)} />}
      {message && (
        <p className="rounded-xl border border-emerald-500/30 bg-emerald-500/10 px-3 py-2 text-sm text-emerald-200">
          {message}
        </p>
      )}

      <div className="grid gap-4 lg:grid-cols-2">
        {snap.graphs.map((graph) => {
          const draft = drafts[graph.id] || { top_k: "10", min_similarity: "0" };
          const defaults = snap.defaults[graph.id];
          return (
            <div key={graph.id} className={cn(adminCard, "p-4")}>
              <div className="mb-3">
                <h3 className="text-sm font-semibold text-white">{graph.label}</h3>
                <p className="mt-0.5 font-mono text-[10px] text-white/40">{graph.id}</p>
              </div>

              <div className="space-y-3">
                <div>
                  <AdminFieldLabel
                    label="top_k"
                    hint={`Number of legal chunks to retrieve (${limits.top_k_min}–${limits.top_k_max}). Default ${defaults?.top_k ?? "—"}.`}
                  />
                  <input
                    type="number"
                    min={limits.top_k_min}
                    max={limits.top_k_max}
                    className={adminInput}
                    value={draft.top_k}
                    onChange={(e) =>
                      setDrafts((prev) => ({
                        ...prev,
                        [graph.id]: { ...draft, top_k: e.target.value },
                      }))
                    }
                  />
                </div>
                <div>
                  <AdminFieldLabel
                    label="min_similarity"
                    hint="Drop results below this cosine similarity (0–1). Use 0 to disable filtering."
                  />
                  <input
                    type="number"
                    min={0}
                    max={1}
                    step={0.01}
                    className={adminInput}
                    value={draft.min_similarity}
                    onChange={(e) =>
                      setDrafts((prev) => ({
                        ...prev,
                        [graph.id]: { ...draft, min_similarity: e.target.value },
                      }))
                    }
                  />
                  <p className="mt-1 text-[10px] text-white/35">
                    {Number(draft.min_similarity) > 0
                      ? `Filter on: keep rows with similarity ≥ ${draft.min_similarity}`
                      : "Filtering off (keep all top_k results)"}
                  </p>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </AdminTabPage>
  );
}
