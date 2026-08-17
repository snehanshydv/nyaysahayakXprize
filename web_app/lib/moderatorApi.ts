const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

function authHeaders(): HeadersInit {
  if (typeof window === "undefined") return {};
  const token = localStorage.getItem("nyaya_access_token");
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;
  return headers;
}

export type ModeratorStats = {
  cases_per_hour: number;
  assigned_in_hour: number;
  capacity_remaining: number;
  open_pending: number;
  sla_minutes: number;
  delay_tick_minutes: number;
  respect_score: number;
  delay_score_total: number;
  cases_resolved: number;
  cases_breached: number;
  overdue_open: number;
};

export async function fetchModeratorStats(): Promise<ModeratorStats> {
  const res = await fetch(`${API_URL}/api/moderator/stats`, { headers: authHeaders() });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.detail || "Failed to load stats");
  return data as ModeratorStats;
}

export async function fetchMyInterventions(): Promise<{ cases: any[]; stats: ModeratorStats }> {
  const res = await fetch(`${API_URL}/api/interventions/moderator/mine`, {
    headers: authHeaders(),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.detail || "Failed to load queue");
  return { cases: data.cases || [], stats: data.stats };
}

export async function fetchModeratorHistory(limit = 50): Promise<any[]> {
  const res = await fetch(
    `${API_URL}/api/interventions/moderator/history?limit=${limit}`,
    { headers: authHeaders() }
  );
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.detail || "Failed to load history");
  return data.cases || [];
}

export async function resolveIntervention(body: {
  case_id: string;
  moderator_response: string;
  moderator_options: unknown[];
  routing_recommendation?: unknown;
  moderator_id?: string;
}): Promise<void> {
  const res = await fetch(`${API_URL}/api/interventions/resolve`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.detail || "Failed to resolve");
  }
}
