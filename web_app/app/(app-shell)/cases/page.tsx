"use client";

import { Suspense, useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { ChatInterface } from "@/components/chat/ChatInterface";
import { useAuth } from "@/context/AuthContext";
import { useGlobalChat } from "@/context/ChatContext";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

/** Load an existing session from ?session= only; strip query after hydrate. */
function CasesSessionBootstrap() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const { user } = useAuth();
  const {
    setActiveSessionId,
    setActiveSession,
    historyCache,
    updateHistoryCache,
    sessionCache,
    setSessionCache,
  } = useGlobalChat();

  useEffect(() => {
    const sessionId = searchParams.get("session");
    if (!sessionId) return;

    setActiveSessionId(sessionId);

    const cached = sessionCache?.find((s: { id: string; session_data?: unknown[] }) => s.id === sessionId);
    if (cached?.session_data) {
      setActiveSession(Array.isArray(cached.session_data) ? cached.session_data : []);
      router.replace("/cases", { scroll: false });
      return;
    }
    if (historyCache[sessionId]?.length) {
      setActiveSession(historyCache[sessionId]);
      router.replace("/cases", { scroll: false });
      return;
    }

    if (!user?.uid) return;
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch(`${API_URL}/api/chat/sessions?uid=${encodeURIComponent(user.uid)}`);
        if (!res.ok) return;
        const data = await res.json();
        const rows = data.sessions || [];
        if (!cancelled && rows.length) setSessionCache(rows);
        const match = rows.find((s: { id: string; session_data?: unknown[] }) => s.id === sessionId);
        if (match && !cancelled) {
          const hist = Array.isArray(match.session_data) ? match.session_data : [];
          setActiveSession(hist);
          updateHistoryCache(sessionId, hist);
        }
      } catch {
        /* ignore */
      } finally {
        if (!cancelled) router.replace("/cases", { scroll: false });
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [
    searchParams,
    user?.uid,
    sessionCache,
    setSessionCache,
    historyCache,
    updateHistoryCache,
    setActiveSessionId,
    setActiveSession,
    router,
  ]);

  return null;
}

export default function CasesPage() {
  return (
    <div className="flex h-full min-h-0 flex-1 flex-col overflow-hidden bg-[#F8F9FA]">
      <Suspense fallback={null}>
        <CasesSessionBootstrap />
      </Suspense>
      <ChatInterface />
    </div>
  );
}
