import type { SidebarCaseSession } from "@/lib/home/mockData";

export type CachedChatSession = {
  id: string;
  session_data?: Array<{ role?: string; content?: string; type?: string }>;
  updated_at?: string;
};

export function sessionTitle(session: CachedChatSession): string {
  const data = session.session_data || [];
  const firstUser = data.find((m) => m.role === "user" || m.type === "user");
  const text = (firstUser?.content || "").trim();
  if (!text) return "Untitled case";
  return text.length > 42 ? `${text.slice(0, 42)}…` : text;
}

export function sessionPreview(session: CachedChatSession): string {
  const data = session.session_data || [];
  const last = [...data].reverse().find((m) => (m.content || "").trim());
  const text = (last?.content || "No messages yet").trim();
  return text.length > 56 ? `${text.slice(0, 56)}…` : text;
}

export function toSidebarSession(session: CachedChatSession): SidebarCaseSession {
  return {
    id: session.id,
    title: sessionTitle(session),
    preview: sessionPreview(session),
    updated_at: session.updated_at || new Date().toISOString(),
  };
}
