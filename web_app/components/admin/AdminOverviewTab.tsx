"use client";

import { useCallback, useEffect, useState } from "react";
import { AdminTabPage } from "@/components/admin/AdminPageLayout";
import { AdminAiUsageCharts } from "@/components/admin/AdminAiUsageCharts";
import {
  AdminErrorBanner,
  AdminLoading,
  AdminStatCard,
  adminBtnSecondary,
  adminSelect,
} from "@/components/admin/admin-ui";
import { adminApi, type AiUsageAnalytics, type MlHealth } from "@/lib/adminApi";
import type { AdminTabId } from "@/components/admin/admin-nav-config";

type Props = {
  onNavigate: (tab: AdminTabId) => void;
};

export function AdminOverviewTab({ onNavigate }: Props) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [health, setHealth] = useState<any>(null);
  const [tables, setTables] = useState<{ name: string; row_count: number | null }[]>([]);
  const [graphs, setGraphs] = useState<any[]>([]);
  const [runs, setRuns] = useState<any[]>([]);
  const [auditTotal, setAuditTotal] = useState(0);
  const [mlHealth, setMlHealth] = useState<MlHealth | null>(null);
  const [usage, setUsage] = useState<AiUsageAnalytics | null>(null);
  const [usageDays, setUsageDays] = useState(7);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [h, t, g, r, audit, ml, aiUsage] = await Promise.all([
        adminApi.health().catch(() => null),
        adminApi.tables(),
        adminApi.graphs(),
        adminApi.runs().catch(() => ({ runs: [] })),
        adminApi.auditLogs(1, 0).catch(() => ({ total: 0, logs: [] })),
        adminApi.mlHealth().catch(() => null),
        adminApi.aiUsage(usageDays).catch(() => null),
      ]);
      setHealth(h);
      setTables(t.tables || []);
      setGraphs(g.graphs || []);
      setRuns(r.runs || []);
      setAuditTotal(audit.total || 0);
      setMlHealth(ml);
      setUsage(aiUsage);
    } catch (e: any) {
      setError(e.message || "Failed to load overview");
    } finally {
      setLoading(false);
    }
  }, [usageDays]);

  useEffect(() => {
    void load();
  }, [load]);

  const totalRows = tables.reduce((sum, t) => sum + (t.row_count || 0), 0);

  return (
    <AdminTabPage
      badge="Main"
      title="Overview"
      description="Platform health, embedding API status, LangGraph registry, and AI usage analytics."
      actions={
        <div className="flex flex-wrap items-center gap-2">
          <select
            className={`${adminSelect} text-xs`}
            value={usageDays}
            onChange={(e) => setUsageDays(parseInt(e.target.value, 10))}
            aria-label="Analytics period"
          >
            <option value={1}>Last 24 hours</option>
            <option value={7}>Last 7 days</option>
            <option value={14}>Last 14 days</option>
            <option value={30}>Last 30 days</option>
          </select>
          <button type="button" className={adminBtnSecondary} onClick={() => void load()} disabled={loading}>
            Refresh
          </button>
        </div>
      }
    >
      {error && <AdminErrorBanner message={error} onDismiss={() => setError(null)} />}
      {loading && !tables.length ? (
        <AdminLoading label="Loading overview…" />
      ) : (
        <div className="space-y-6">
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <AdminStatCard
              label="Tables"
              value={String(tables.length)}
              sub={`${totalRows.toLocaleString()} total rows`}
              accent="blue"
            />
            <AdminStatCard
              label="LangGraph graphs"
              value={String(graphs.length)}
              sub={graphs.map((g) => g.graph_id).join(", ") || "none"}
              accent="violet"
            />
            <AdminStatCard
              label="Recent test runs"
              value={String(runs.length)}
              sub="From langgraph_runs"
              accent="amber"
            />
            <AdminStatCard
              label="Audit entries"
              value={String(auditTotal)}
              sub="admin_audit_logs"
              accent="red"
            />
            <AdminStatCard
              label="Database"
              value={health?.database ? "OK" : "—"}
              sub={health?.database?.database || "postgres"}
              accent="emerald"
            />
            <AdminStatCard
              label="Embedding API"
              value={mlHealth?.ok ? "Healthy" : "Check"}
              sub={mlHealth?.model || "Vyakyarth"}
              accent={mlHealth?.ok ? "emerald" : "amber"}
            />
            <AdminStatCard
              label="AI requests"
              value={String(usage?.totals.requests ?? 0)}
              sub={`Last ${usageDays} days`}
              accent="blue"
            />
            <AdminStatCard
              label="AI tokens"
              value={(usage?.totals.tokens ?? 0).toLocaleString()}
              sub={`Last ${usageDays} days`}
              accent="violet"
            />
          </div>

          <div className="grid gap-4 lg:grid-cols-2">
            <section className="rounded-[20px] border border-white/[0.09] bg-[#0c0c0c] p-5">
              <h2 className="text-sm font-semibold text-white/85">Quick actions</h2>
              <p className="mt-1 text-xs text-white/40">Jump into monitoring and configuration.</p>
              <div className="mt-4 flex flex-wrap gap-2">
                <button type="button" className={adminBtnSecondary} onClick={() => onNavigate("langgraph")}>
                  Test LangGraph
                </button>
                <button type="button" className={adminBtnSecondary} onClick={() => onNavigate("ai")}>
                  AI & models
                </button>
                <button type="button" className={adminBtnSecondary} onClick={() => onNavigate("audit")}>
                  Audit log
                </button>
                <button type="button" className={adminBtnSecondary} onClick={() => onNavigate("cases")}>
                  User cases
                </button>
                <button type="button" className={adminBtnSecondary} onClick={() => onNavigate("cms")}>
                  CMS
                </button>
                <button type="button" className={adminBtnSecondary} onClick={() => onNavigate("payments")}>
                  Payments
                </button>
                <button type="button" className={adminBtnSecondary} onClick={() => onNavigate("tables")}>
                  Browse tables
                </button>
                <button type="button" className={adminBtnSecondary} onClick={() => onNavigate("sql")}>
                  SQL console
                </button>
              </div>
            </section>

            <section className="rounded-[20px] border border-white/[0.09] bg-[#0c0c0c] p-5">
              <h2 className="text-sm font-semibold text-white/85">ML / embedding health</h2>
              <p className="mt-1 text-xs text-white/40">Nyaysahayak embedding service probe.</p>
              <dl className="mt-4 space-y-2 font-mono text-[11px] text-white/60">
                <div className="flex justify-between gap-3">
                  <dt className="text-white/35">URL</dt>
                  <dd className="truncate text-right">{mlHealth?.embedding_url || "—"}</dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-white/35">Model</dt>
                  <dd>{mlHealth?.model || "—"}</dd>
                </div>
                <div className="flex justify-between gap-3">
                  <dt className="text-white/35">Status</dt>
                  <dd className={mlHealth?.ok ? "text-emerald-400" : "text-amber-300"}>
                    {mlHealth?.ok ? "ok" : mlHealth?.error || "unavailable"}
                  </dd>
                </div>
              </dl>
            </section>
          </div>

          {usage && <AdminAiUsageCharts analytics={usage} />}
        </div>
      )}
    </AdminTabPage>
  );
}
