"use client";

import { useState, useRef, useEffect } from "react";
import { Send, CheckCircle, Sparkles, MessageSquare, Plus, ChevronDown, Menu, MapPin } from "lucide-react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";

// import { AgentLog } from "./AgentLog";
import { VoiceInput, VoiceInputRef } from "./VoiceInput";
import { PDFDownloadPanel } from "./PDFDownloadPanel";
import { AuthModal } from "@/components/auth/AuthModal";
import { CaseHomeLanding } from "@/components/home/CaseHomeLanding";
import { CaseChatMessageList } from "@/components/chat/CaseChatMessageList";
import { useAuth } from "@/context/AuthContext";
import { useGlobalChat } from "@/context/ChatContext";
import { cn } from "@/lib/utils";
import { panelMotion, touchIconButton, touchIconButtonCompact } from "@/lib/motion";
import { db } from "@/lib/firebase";
import { doc, onSnapshot } from "firebase/firestore";
import { LawyerBrowserPanel, LawyerProfile } from "./LawyerBrowserPanel";
import { SahayakBrowserPanel } from "./SahayakBrowserPanel";
import { NodalGuideBrowserPanel } from "./NodalGuideBrowserPanel";
import { FemaleNyayGuidePanel } from "./FemaleCounsellorPanel";
import { RoutingConsentModal } from "./RoutingConsentModal";
interface Message {
  role: "user" | "assistant";
  content: string;
  agent?: string; // Add agent field
}

interface LogEntry {
  type: string;
  agent?: string;
  content: string;
  timestamp: string;
}

const SUGGESTED_QUESTIONS = [
  { icon: MessageSquare, text: "How do I file a property dispute case?", payload: "I want to file a property dispute case. What is the procedure?" },
  { icon: Sparkles, text: "Check my consumer rights", payload: "What are my basic consumer rights in India?" },
  { icon: CheckCircle, text: "Verify a legal document", payload: "How can I verify if a property document is authentic?" },
];

export function ChatInterface() {
  const pathname = usePathname();
  const isCasesPage = pathname === "/cases";
  const [query, setQuery] = useState("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [structuredReport, setStructuredReport] = useState<any>(null);
  const [suggestedActions, setSuggestedActions] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isLogOpen, setIsLogOpen] = useState(true);
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);
  const [currentCaseId, setCurrentCaseId] = useState<string | null>(null);
  const [currentCasePending, setCurrentCasePending] = useState(false);
  const [questionFlowActive, setQuestionFlowActive] = useState(false);
  
  // Lawyer browser panel state
  const [recommendedLawyers, setRecommendedLawyers] = useState<LawyerProfile[]>([]);
  const [lawyerCaseId, setLawyerCaseId] = useState<string | null>(null);
  const [showLawyerPanel, setShowLawyerPanel] = useState(false);

  // Sahayak browser panel state
  const [recommendedSahayaks, setRecommendedSahayaks] = useState<any[]>([]);
  const [sahayakCaseId, setSahayakCaseId] = useState<string | null>(null);
  const [showSahayakPanel, setShowSahayakPanel] = useState(false);
  const [acceptedSahayakId, setAcceptedSahayakId] = useState<string | null>(null);

  // Nodal Guide modal panel state
  const [nodalGuideProfiles, setNodalGuideProfiles] = useState<any[]>([]);
  const [showNodalGuidePanel, setShowNodalGuidePanel] = useState(false);
  const [routingRecommendation, setRoutingRecommendation] = useState<any | null>(null);
  const [showRoutingConsentModal, setShowRoutingConsentModal] = useState(false);
  const [femaleNyayGuideProfiles, setFemaleNyayGuideProfiles] = useState<any[]>([]);
  const [showFemaleNyayGuidePanel, setShowFemaleNyayGuidePanel] = useState(false);
  
  // PDF download state - automatically populated when pdf_ready event received
  const [currentPdfUrl, setCurrentPdfUrl] = useState<string | null>(null);
  
  // Global Chat Context
  const { 
    activeQuery, activeSession, activeSessionId, clearActiveQuery, clearActiveSession,
    setActiveSessionId, historyCache, updateHistoryCache, sessionCache, upsertSessionInCache,
    chatResetNonce,
  } = useGlobalChat();

  // Local Session ID
  const [localSessionId, setLocalSessionId] = useState<string>("");

  // Input collapse state: collapses after each submit, expands on click
  const [isInputCollapsed, setIsInputCollapsed] = useState(false);

  // TTS playback state
  const [isPlayingTTS, setIsPlayingTTS] = useState(false);
  const currentAudioRef = useRef<HTMLAudioElement | null>(null);

  const stopTTS = () => {
    if (currentAudioRef.current) {
      currentAudioRef.current.pause();
      currentAudioRef.current.src = "";
      currentAudioRef.current = null;
    }
    setIsPlayingTTS(false);
  };

  const cleanTTS = (text: string) => {
    return text
      .replace(/https?:\/\/[^\s]+/g, '')
      .replace(/<[^>]*>?/gm, '')
      .replace(/\[.*?\]/g, '')
      .replace(/\{.*?\}/g, '')
      .replace(/[*_#`~>-]/g, '')
      .replace(/\s{2,}/g, ' ')
      .trim();
  };

  useEffect(() => {
    if (activeSessionId) {
      setLocalSessionId(activeSessionId);
      lastFetchedSessionRef.current = "";
    } else if (!localSessionId) {
      const sid = crypto.randomUUID();
      setLocalSessionId(sid);
      setActiveSessionId(sid);
    }
  }, [activeSessionId, localSessionId, setActiveSessionId]);
  
  // Real-time Intervention State
  const [interventionCaseId, setInterventionCaseId] = useState<string | null>(null);
  const [interventionCollection, setInterventionCollection] = useState<string>("moderator");

  // Auth state
  const { user, role, loading: authLoading } = useAuth();
  const [showAuthModal, setShowAuthModal] = useState(false);
  const MESSAGE_LIMIT = 10;

  const buildUserWebSocketUrl = (uid: string) => {
    const rawApiUrl = (process.env.NEXT_PUBLIC_API_URL || "").trim();

    if (rawApiUrl) {
      try {
        const parsed = new URL(rawApiUrl);
        const wsProtocol = parsed.protocol === "https:" ? "wss:" : "ws:";
        const cleanedPath = parsed.pathname.replace(/\/$/, "");
        return `${wsProtocol}//${parsed.host}${cleanedPath}/ws/user/${uid}`;
      } catch {
        // fallback to relative host below
      }
    }

    if (typeof window !== "undefined") {
      const wsProtocol = window.location.protocol === "https:" ? "wss:" : "ws:";
      return `${wsProtocol}//${window.location.host}/ws/user/${uid}`;
    }

    return `ws://localhost:8000/ws/user/${uid}`;
  };

  // Session ID
  const userIdRef = useRef(user?.uid || `anon_${Math.floor(Math.random() * 1000)}`);
  const lastScrollTime = useRef(0);
  // Stable refs for WS handler — avoids closing/reopening WS on state changes
  const interventionCaseIdRef = useRef<string | null>(null);
  const localSessionIdRef = useRef<string>("");
  const wsRef = useRef<WebSocket | null>(null);
  // Track which session we've already fetched so we don't hit the API more than once per session
  const lastFetchedSessionRef = useRef<string>("");
  const prevActiveSessionRef = useRef<string | null>(null);
  const lastChatResetNonceRef = useRef(0);
  const messagesSessionIdRef = useRef<string | null>(null);

  useEffect(() => {
    if (chatResetNonce === lastChatResetNonceRef.current) return;
    lastChatResetNonceRef.current = chatResetNonce;

    messagesSessionIdRef.current = null;
    setMessages([]);
    setStructuredReport(null);
    setSuggestedActions([]);
    setLogs([]);
    setQuery("");
    currentAgentRef.current = null;
    displayAgentRef.current = null;
    clearActiveSession();
    clearActiveQuery();
    lastFetchedSessionRef.current = "";
    prevActiveSessionRef.current = null;
    setIsInputCollapsed(false);
    setRecommendedLawyers([]);
    setShowLawyerPanel(false);
    setLawyerCaseId(null);
    setCurrentPdfUrl(null);
    setQuestionFlowActive(false);
    setRoutingRecommendation(null);
    setShowRoutingConsentModal(false);
    setFemaleNyayGuideProfiles([]);
    setShowFemaleNyayGuidePanel(false);

    if (activeSessionId) {
      setLocalSessionId(activeSessionId);
      localSessionIdRef.current = activeSessionId;
    }
  }, [chatResetNonce, activeSessionId, clearActiveSession, clearActiveQuery]);

  // Auto-submit from context — wait until session id is ready
  useEffect(() => {
    if (!activeQuery || isLoading || !localSessionId) return;
    const q = activeQuery;
    clearActiveQuery();
    void handleSubmit(undefined, q);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeQuery, isLoading, localSessionId]);

  // Load Active Session from Context (e.g. from My Cases / sidebar)
  useEffect(() => {
    if (activeSession && Array.isArray(activeSession) && activeSession.length > 0) {
      messagesSessionIdRef.current = activeSessionId ?? localSessionId;
      setMessages(activeSession as Message[]);
      clearActiveSession();
    } else if (activeSession) {
      clearActiveSession();
    }
  }, [activeSession]);

  useEffect(() => {
    if (!activeSessionId || activeSessionId !== localSessionId) return;
    if (prevActiveSessionRef.current === activeSessionId) return;
    prevActiveSessionRef.current = activeSessionId;

    if (activeQuery) return;
    if (activeSession && activeSession.length > 0) return;

    const hist = historyCache[activeSessionId];
    const fromCache = sessionCache?.find((s: { id: string; session_data?: unknown[] }) => s.id === activeSessionId);
    const hasData =
      (hist?.length ?? 0) > 0 ||
      (Array.isArray(fromCache?.session_data) ? fromCache.session_data.length : 0) > 0;

    if (!hasData) {
      messagesSessionIdRef.current = null;
      setMessages([]);
      setStructuredReport(null);
      setSuggestedActions([]);
      setIsInputCollapsed(false);
    }
  }, [activeSessionId, localSessionId, activeQuery, activeSession, historyCache, sessionCache]);

  useEffect(() => {
    if (user && localSessionId) {
      setCurrentCaseId(null);
      setCurrentPdfUrl(null);
      setCurrentCasePending(false);
      userIdRef.current = user.uid;
      if (lastFetchedSessionRef.current !== localSessionId) {
        lastFetchedSessionRef.current = localSessionId;
        loadChatFromFirestore(user.uid, localSessionId);
        restoreSahayakPanel(localSessionId);
      }
    }
  }, [user?.uid, localSessionId]);

  // Keep refs in sync with state so the WS handler always reads fresh values without re-mounting
  useEffect(() => { interventionCaseIdRef.current = interventionCaseId; }, [interventionCaseId]);
  useEffect(() => { localSessionIdRef.current = localSessionId; }, [localSessionId]);

  // Real-time WebSocket Listener for Moderator Intervention
    // 🔌 WebSocket Management for Real-time Updates (Intervention Status)
    // IMPORTANT: depends ONLY on user.uid so it never tears down mid-session unexpectedly
    useEffect(() => {
        if (!user || authLoading) return;

        let destroyed = false;
        let reconnectTimeout: NodeJS.Timeout;
        let wsWarned = false;

        const connect = () => {
            if (destroyed) return;

          const wsUrl = buildUserWebSocketUrl(user.uid);
            const ws = new WebSocket(wsUrl);
            wsRef.current = ws;

            ws.onopen = () => {
                wsWarned = false;
            };

            ws.onmessage = (event) => {
                try {
                    const data = JSON.parse(event.data);
                    console.log("📩 WebSocket message received:", data.type);
          // Read from refs so we never need stale closure values
          const currentCaseId = interventionCaseIdRef.current;
          const currentSessionId = localSessionIdRef.current;

          if (data.type === "intervention_resolved") {
            const matchesByCase = currentCaseId && data.case_id === currentCaseId;
            const matchesBySession = currentSessionId && data.session_id === currentSessionId;
            if (matchesByCase || matchesBySession) {
              // Break the loading lock and present the moderator's response
              setIsLoading(false);
              let nextHistory: Message[] | null = null;
              const moderatorText = data.moderator_response || "A moderator has reviewed your case.";

              setMessages(prev => {
                const lastMsg = prev[prev.length - 1];
                if (lastMsg && lastMsg.agent === "legal_moderator" && lastMsg.content === moderatorText) {
                  return prev;
                }
                const newHistory: Message[] = [...prev, {
                  role: "assistant",
                  content: moderatorText,
                  agent: "legal_moderator"
                }];
                nextHistory = newHistory;
                return newHistory;
              });

              if (currentSessionId && nextHistory) {
                setTimeout(() => updateHistoryCache(currentSessionId, nextHistory as Message[]), 0);
              }

              const opts = data.moderator_options;
              let routingFromModerator: any = data.routing_recommendation || null;
              if (Array.isArray(opts) && opts.length > 0) {
                const cleanOpts = opts.filter((opt: any) => {
                  if (!opt || typeof opt !== "object") return true;
                  if (opt.type === "routing_bundle" && opt.routing_recommendation && !routingFromModerator) {
                    routingFromModerator = opt.routing_recommendation;
                    return false;
                  }
                  return opt.type !== "routing_bundle";
                });
                setSuggestedActions(cleanOpts);
              } else if (typeof opts === 'string') {
                try {
                  const parsed = JSON.parse(opts);
                  if (Array.isArray(parsed) && parsed.length > 0) {
                    const cleanParsed = parsed.filter((opt: any) => {
                      if (!opt || typeof opt !== "object") return true;
                      if (opt.type === "routing_bundle" && opt.routing_recommendation && !routingFromModerator) {
                        routingFromModerator = opt.routing_recommendation;
                        return false;
                      }
                      return opt.type !== "routing_bundle";
                    });
                    setSuggestedActions(cleanParsed);
                  }
                } catch (_) { /* ignore */ }
              }
              if (routingFromModerator) {
                setRoutingRecommendation(routingFromModerator);
                setShowRoutingConsentModal(true);
              }
              setInterventionCaseId(null);
              setCurrentCasePending(false);
            }
          }
        } catch (e) {
          console.error("Error parsing websocket message in chat interface:", e);
        }
      };

            ws.onerror = () => {
                if (!wsWarned) {
                    wsWarned = true;
                    console.debug(
                      "Realtime updates unavailable (WebSocket). Chat still works; start the backend for live moderator push."
                    );
                }
            };

            ws.onclose = (event) => {
                if (!destroyed && event.code !== 1000) {
                    reconnectTimeout = setTimeout(connect, 5000);
                }
            };
        };

        connect();

        return () => {
            destroyed = true;
            if (reconnectTimeout) clearTimeout(reconnectTimeout);
            if (wsRef.current && (wsRef.current.readyState === WebSocket.OPEN || wsRef.current.readyState === WebSocket.CONNECTING)) {
                wsRef.current.close(1000, "Component unmounting");
            }
        };
    }, [user?.uid, authLoading]);

  const loadChatFromFirestore = async (uid: string, sessionId?: string) => {
    // Check Cache First
    if (sessionId && historyCache[sessionId] && historyCache[sessionId].length > 0) {
      messagesSessionIdRef.current = sessionId;
      setMessages(historyCache[sessionId] as Message[]);
      
      // Restore options from the last message if available from cache
      const lastMsg = historyCache[sessionId][historyCache[sessionId].length - 1];
      if (lastMsg.options && Array.isArray(lastMsg.options)) {
        setSuggestedActions(lastMsg.options);
      } else {
        setSuggestedActions([]);
      }
      // Still try to restore sahayak panel from Supabase even when using cache
      if (sessionId) {
        restoreSahayakPanel(sessionId);
        restoreCasePdf(sessionId, uid);
      }
      return; // Exit early since we used cache
    }

    try {
      let url = `${process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"}/api/chat/history?uid=${uid}`;
      if (sessionId) {
        url += `&session_id=${sessionId}`;
      }
      const response = await fetch(url);
      if (response.ok) {
        const data = await response.json();
        if (data.history) {
          if (sessionId) messagesSessionIdRef.current = sessionId;
          setMessages(data.history);
          if (sessionId) {
            updateHistoryCache(sessionId, data.history);
          }
          // Restore options from the last message if available
          if (data.history.length > 0) {
            const lastMsg = data.history[data.history.length - 1];
            if (lastMsg.options && Array.isArray(lastMsg.options)) {
              setSuggestedActions(lastMsg.options);
            } else {
              setSuggestedActions([]);
            }
          }
        } else {
          setMessages([]);
          if (sessionId) updateHistoryCache(sessionId, []);
        }
        // Restore sahayak panel if this session had one
        if (sessionId) {
          restoreSahayakPanel(sessionId);
          restoreCasePdf(sessionId, uid);
        }
      }
    } catch (err) {
      console.error("Error loading chat history:", err);
    }
  };

  const restoreCasePdf = async (sessionId: string, uid: string) => {
    try {
      const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";
      const res = await fetch(`${API_URL}/api/cases?uid=${encodeURIComponent(uid)}`);
      if (!res.ok) return;

      const data = await res.json();
      if (data.status !== "success" || !Array.isArray(data.cases)) return;

      // Bind to the currently open chat session only, and only to its latest case record.
      // This prevents stale PDFs from older cases in the same session from being shown.
      const sessionCases = data.cases.filter((c: any) => c?.session_id === sessionId);
      const latestSessionCase = sessionCases.length > 0 ? sessionCases[0] : null;

      if (!latestSessionCase || !latestSessionCase.pdf_url) {
        setCurrentCaseId(null);
        setCurrentPdfUrl(null);
        setCurrentCasePending(Boolean(latestSessionCase?.pending));
        return;
      }

      if (latestSessionCase.case_id) {
        setCurrentCaseId(latestSessionCase.case_id);
      }
      if (latestSessionCase.pdf_url) {
        setCurrentPdfUrl(latestSessionCase.pdf_url);
      }
      setCurrentCasePending(Boolean(latestSessionCase.pending));
    } catch (err) {
      console.error("Error restoring case PDF:", err);
    }
  };

  /**
   * Checks Supabase for a sahayak case linked to this session.
   * - If case is "accepted": shows the assigned guide's profile card (read-only).
   * - If case is "pending":  shows the browsing panel so user can still pick a guide.
   */
  const restoreSahayakPanel = async (sessionId: string) => {
    try {
      const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";
      const res = await fetch(`${API_URL}/api/sahayak/session-case?session_id=${encodeURIComponent(sessionId)}`);
      if (!res.ok) return;
      const data = await res.json();
      if (data.status !== "success" || !data.case) return;

      const sc = data.case;
      setSahayakCaseId(sc.id);

      if (sc.status === "accepted" && sc.assigned_sahayak_profile) {
        // Convert db profile → panel format and show as single-item list (the assigned guide)
        const p = sc.assigned_sahayak_profile;
        setRecommendedSahayaks([{
          uid: p.uid || sc.assigned_sahayak_id,
          name: p.name || sc.assigned_sahayak_name || "Nyay Guide",
          location: p.location || "",
          occupation: p.occupation || "Community Legal Aid",
          bio: p.bio || "",
          avatar: p.avatar || "",
          contact_number: p.contact_number || "",
          email: p.email || "",
          availability: p.availability || "Available",
          rating: p.rating || 4.5,
          cases_resolved: p.cases_resolved || 0,
          languages: p.languages || [],
          isAssigned: true, // flag so panel can show "Already connected" state
        }]);
        setAcceptedSahayakId(sc.assigned_sahayak_id || null);
        setShowSahayakPanel(true);
      } else if (sc.status === "pending") {
        // Fetch all profiles for browsing (user hasn't picked yet)
        const profRes = await fetch(`${API_URL}/api/sahayak/profiles`);
        if (profRes.ok) {
          const profData = await profRes.json();
          if (profData.profiles && profData.profiles.length > 0) {
            setRecommendedSahayaks(profData.profiles.map((p: any) => ({
              uid: p.uid, name: p.name, location: p.location, occupation: p.occupation,
              bio: p.bio, avatar: p.avatar, contact_number: p.contact_number,
              email: p.email, availability: p.availability,
              rating: p.rating || 4.5, cases_resolved: p.cases_resolved || 0,
              languages: p.languages || [],
            })));
            setShowSahayakPanel(true);
          }
        }
      }
    } catch (err) {
      console.error("Error restoring sahayak panel:", err);
    }
  };

  // Validation state (reset on new query)
  const [validationComplete, setValidationComplete] = useState(false);

  // Handle Copy
  const handleCopy = (text: string, index: number) => {
    navigator.clipboard.writeText(text);
    setCopiedIndex(index);
    setTimeout(() => setCopiedIndex(null), 2000);
  };

  // Reset validation state on new query
  useEffect(() => {
    if (isLoading) {
      setValidationComplete(false);
    }
  }, [isLoading]);

  const currentAgentRef = useRef<string | null>(null);
  const displayAgentRef = useRef<string | null>(null);
  const [selectedContexts, setSelectedContexts] = useState<string[]>([]);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const voiceInputRef = useRef<VoiceInputRef>(null);
  const isConversationActive = useRef<boolean>(false);
  const savedCaseIdsRef = useRef<Set<string>>(new Set());
  const completedCaseIdsRef = useRef<Set<string>>(new Set());

  // Auto-resize textarea
  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 120)}px`;
    }
  }, [query]);

  // Geolocation Request — GPS first; if denied, supervisor will ask for area
  const [userLocation, setUserLocation] = useState<{ lat: number; lon: number } | null>(null);
  const [locationDenied, setLocationDenied] = useState(false);
  const [resolvedLocation, setResolvedLocation] = useState<{
    city?: string;
    state?: string;
    source?: string;
  } | null>(null);

  useEffect(() => {
    if (!("geolocation" in navigator)) {
      setLocationDenied(true);
      return;
    }
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setUserLocation({
          lat: position.coords.latitude,
          lon: position.coords.longitude,
        });
        setLocationDenied(false);
      },
      (error) => {
        // Permission denied is expected — don't spam the console
        if (error.code !== 1) {
          console.debug("Geolocation unavailable:", error.message);
        }
        setUserLocation(null);
        setLocationDenied(true);
      },
      { timeout: 8000, maximumAge: 300000 }
    );
  }, []);

  // Unified Stream Processor
  const processStream = async (reader: ReadableStreamDefaultReader<Uint8Array>) => {
    const decoder = new TextDecoder();
    let assistantMessage = "";
    let finalCleanContent = "";
    let ndjsonBuffer = "";

    const stripAnswerPrefix = (raw: string) => {
      let cleanContent = raw;
      const stripPatterns = [
        /^Output:\s*(?:civil|cyber|criminal|domestic|scam|document|sahayak|legal_moderator|lawyer_forwarder)\s*/i,
        /^(?:civil|cyber|criminal|domestic|scam|document|sahayak|supervisor|assistant)\s*:\s*/i,
        /^(?:civil|cyber|criminal|domestic|scam|document|sahayak|legal\s*moderator|lawyer\s*forwarder|supervisor)\s*agent\s*:\s*/i,
        /^I'm\s+the\s+(?:civil|cyber|criminal|domestic|scam|document|sahayak)\s+agent[.,!\s]*/i,
        /^I\s+am\s+the\s+(?:civil|cyber|criminal|domestic|scam|document|sahayak)\s+agent[.,!\s]*/i,
        /^AI\s*(?:Legal\s*)?Assistant\s*:\s*/i,
        /^Legal\s*Moderator\s*:\s*/i,
      ];
      stripPatterns.forEach((regex) => {
        cleanContent = cleanContent.replace(regex, "");
      });
      if (currentAgentRef.current) {
        const agentName = currentAgentRef.current.replace(/_/g, "[_ ]?");
        cleanContent = cleanContent
          .replace(new RegExp(`^${agentName}[\\s_]?agent:\\s*`, "i"), "")
          .replace(new RegExp(`^${agentName}:\\s*`, "i"), "");
      }
      return cleanContent.trimStart();
    };

    let lastAnswerPaintAt = 0;
    let answerPaintTimer: ReturnType<typeof setTimeout> | null = null;

    const paintAssistantMessage = () => {
      setMessages((prev) => {
        const lastIdx = prev.length - 1;
        const lastMsg = prev[lastIdx];
        if (lastMsg && lastMsg.role === "assistant") {
          const newMsgs = [...prev];
          newMsgs[lastIdx] = {
            ...lastMsg,
            content: finalCleanContent,
            agent: lastMsg.agent || displayAgentRef.current || currentAgentRef.current || undefined,
          };
          return newMsgs;
        }
        return prev;
      });
    };

    const applyAnswerToken = (token: string) => {
      assistantMessage += token;
      finalCleanContent = stripAnswerPrefix(assistantMessage);

      const now = performance.now();
      if (now - lastAnswerPaintAt >= 48) {
        lastAnswerPaintAt = now;
        paintAssistantMessage();
        return;
      }

      if (answerPaintTimer) return;
      answerPaintTimer = setTimeout(() => {
        answerPaintTimer = null;
        lastAnswerPaintAt = performance.now();
        paintAssistantMessage();
      }, 48);
    };

    const flushAnswerToUi = () => {
      if (answerPaintTimer) {
        clearTimeout(answerPaintTimer);
        answerPaintTimer = null;
      }
      if (finalCleanContent) paintAssistantMessage();
    };

    const nextFrame = () =>
      new Promise<void>((resolve) => {
        requestAnimationFrame(() => resolve());
      });

    // Add temporary empty assistant message to stream into
    setMessages((prev) => [...prev, { role: "assistant", content: "" }]);

    const handleStreamEvent = (data: any) => {
      if (data.type === "agent_start") {
        currentAgentRef.current = data.agent;
        const excludedDisplayAgents = ["question_processor", "report_generator", "legal_moderator", "supervisor", "agent"];
        if (!displayAgentRef.current && !excludedDisplayAgents.includes(String(data.agent).toLowerCase())) {
          displayAgentRef.current = data.agent;
        }
        setMessages(prev => {
          const lastIdx = prev.length - 1;
          const lastMsg = prev[lastIdx];
          if (lastMsg && lastMsg.role === "assistant" && !lastMsg.agent) {
            const newMsgs = [...prev];
            newMsgs[lastIdx] = { ...lastMsg, agent: displayAgentRef.current || data.agent };
            return newMsgs;
          }
          return prev;
        });
      } else if (data.type === "log") {
        setLogs(prev => [...prev, {
          type: "log",
          agent: data.agent,
          content: data.content,
          timestamp: new Date().toLocaleTimeString()
        }]);

        if (data.content.startsWith("Transcription: ")) {
          const text = data.content.replace("Transcription: ", "").replace(/^'|'$/g, "");
          setMessages(prev => {
            const newMsgs = [...prev];
            for (let i = newMsgs.length - 1; i >= 0; i--) {
              if (newMsgs[i].role === "user") {
                newMsgs[i] = { ...newMsgs[i], content: "🎤 " + text };
                break;
              }
            }
            return newMsgs;
          });
        }
      } else if (data.type === "lawyer_recommendations") {
        if (data.lawyers && data.lawyers.length > 0) {
          setRecommendedLawyers(data.lawyers);
          setLawyerCaseId(data.lawyer_case_id || null);
          setShowLawyerPanel(true);
        }
      } else if (data.type === "sahayak_recommendations") {
        setRecommendedSahayaks(data.sahayaks || []);
        setSahayakCaseId(data.sahayak_case_id || null);
        setShowSahayakPanel(true);
      } else if (data.type === "nodal_guide_panel") {
        setNodalGuideProfiles(data.profiles || []);
        setShowNodalGuidePanel(true);
      } else if (data.type === "female_nyayguide_panel") {
        setFemaleNyayGuideProfiles(data.profiles || []);
        setShowFemaleNyayGuidePanel(true);
      } else if (data.type === "routing_consent_modal") {
        setRoutingRecommendation(data.routing || null);
        setShowRoutingConsentModal(Boolean(data.routing));
      } else if (data.type === "pending_questions") {
        setQuestionFlowActive(true);
        setStructuredReport(null);
        setSuggestedActions([]);
        setCurrentPdfUrl(null);
        setLogs(prev => [...prev, {
          type: "log",
          agent: "question_processor",
          content: `Question ${Number(data.current_index || 0) + 1} of ${Array.isArray(data.questions) ? data.questions.length : 0} ready`,
          timestamp: new Date().toLocaleTimeString()
        }]);
      } else if (data.type === "pdf_ready") {
        console.log("📄 PDF is ready:", data.pdf_url);
        setQuestionFlowActive(false);
        if (data.case_id) setCurrentCaseId(data.case_id);
        if (data.pdf_url) setCurrentPdfUrl(data.pdf_url);

        if (user && data.case_id && !completedCaseIdsRef.current.has(data.case_id)) {
          completedCaseIdsRef.current.add(data.case_id);
          const completePayload = {
            uid: user.uid,
            case_id: data.case_id,
            session_id: localSessionId,
            structured_report: data.structured_report || structuredReport || {},
            situation_summary: data.situation_summary || {},
            collected_answers: data.collected_answers || {},
            session_data: messages,
            user_language: data.user_language || "english",
            pdf_url: data.pdf_url || null,
            generate_pdf: false
          };
          fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"}/api/cases/complete`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(completePayload)
          }).catch((err) => {
            console.error("Failed to persist completed case:", err);
            completedCaseIdsRef.current.delete(data.case_id);
          });
        }

        setMessages(prev => [...prev, {
          role: "assistant",
          content: `✅ **Case document completed and ready!** Your comprehensive case report with all information has been generated and is ready for download from your case history.`,
          agent: "system"
        }]);
      } else if (data.type === "data") {
        const locFromReport = data.structured_report?.location || data.location || data.situation_summary?.location;
        if (locFromReport && typeof locFromReport === "object") {
          setResolvedLocation({
            city: locFromReport.city,
            state: locFromReport.state,
            source: locFromReport.source,
          });
        }
        const hasPendingQuestions = Array.isArray(data.pending_questions) && data.pending_questions.length > 0;
        if (hasPendingQuestions) {
          setQuestionFlowActive(true);
          setStructuredReport(null);
          setSuggestedActions([]);
          setCurrentPdfUrl(null);
        } else {
          setQuestionFlowActive(false);
          setStructuredReport(data.structured_report || null);
          setSuggestedActions(data.suggested_actions || []);
          if (data.routing_recommendation) setRoutingRecommendation(data.routing_recommendation);
          if (data.show_routing_consent && data.routing_recommendation) setShowRoutingConsentModal(true);
          if (data.show_female_nyayguide_panel) {
            setFemaleNyayGuideProfiles(data.female_nyayguide_profiles || []);
            setShowFemaleNyayGuidePanel(true);
          }
        }
        if (data.case_id) setCurrentCaseId(data.case_id);
        if (data.intervention_required) {
          setInterventionCaseId(data.case_id);
          setInterventionCollection(data.intervention_collection || "moderator");
          setCurrentCasePending(true);
        }

        if (data.structured_report && data.case_id && user && !savedCaseIdsRef.current.has(data.case_id) && !data.case_completed) {
          savedCaseIdsRef.current.add(data.case_id);
          try {
            setMessages(prev => {
              const payload = {
                uid: user.uid,
                case_id: data.case_id,
                structured_report: data.structured_report,
                session_data: prev
              };
              fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"}/api/cases`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload)
              }).catch(console.error);
              return prev;
            });
          } catch (e) {
            console.error("Failed to save formalized case:", e);
          }
        }
      } else if (data.type === "error") {
        console.error("Stream error:", data.content);
        const errText =
          typeof data.content === "string" && data.content.trim()
            ? data.content.trim()
            : "Something went wrong while generating a reply. Please try again.";
        setMessages((prev) => {
          const last = prev[prev.length - 1];
          if (last?.role === "assistant" && !last.content) {
            const next = [...prev];
            next[next.length - 1] = { ...last, content: errText };
            return next;
          }
          return prev;
        });
      }
    };

    const dispatchStreamEvent = async (data: any) => {
      if (data.type === "answer") {
        let token = data.content;
        if (typeof token !== "string") {
          token = typeof token?.text === "string" ? token.text : JSON.stringify(token);
        }
        applyAnswerToken(token);
        await nextFrame();
        return;
      }
      handleStreamEvent(data);
    };

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        // Keep a carry-over buffer so JSON lines split across TCP chunks are not dropped.
        ndjsonBuffer += decoder.decode(value, { stream: true });
        const lines = ndjsonBuffer.split("\n");
        ndjsonBuffer = lines.pop() || "";

        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed) continue;
          try {
            await dispatchStreamEvent(JSON.parse(trimmed));
          } catch (e) {
            console.error("Error parsing NDJSON line:", e);
          }
        }
      }

      if (ndjsonBuffer.trim()) {
        try {
          await dispatchStreamEvent(JSON.parse(ndjsonBuffer.trim()));
        } catch {
          /* ignore trailing partial */
        }
      }
    } catch (err) {
      console.error("Stream reading error:", err);
    }

    flushAnswerToUi();

    // Stream closed with no answer tokens (common when proxies drop mid-specialist).
    if (!finalCleanContent.trim()) {
      setMessages((prev) => {
        const last = prev[prev.length - 1];
        if (last?.role === "assistant" && !String(last.content || "").trim()) {
          const next = [...prev];
          next[next.length - 1] = {
            ...last,
            content:
              "Sorry — the reply didn’t finish coming through. Please send your last message again.",
          };
          return next;
        }
        return prev;
      });
    }

    return finalCleanContent;
  };

  const handleNewChat = () => {
    const newId = crypto.randomUUID();
    messagesSessionIdRef.current = null;
    setMessages([]);
    setStructuredReport(null);
    setSuggestedActions([]);
    setLogs([]);
    setQuery("");
    currentAgentRef.current = null;
    displayAgentRef.current = null;
    clearActiveSession();
    clearActiveQuery();
    setLocalSessionId(newId);
    setActiveSessionId(newId);
    lastFetchedSessionRef.current = "";
    setIsInputCollapsed(false);
    setRecommendedLawyers([]);
    setShowLawyerPanel(false);
    setLawyerCaseId(null);
    setCurrentPdfUrl(null); // Reset PDF URL for new chat
    setQuestionFlowActive(false);
    setRoutingRecommendation(null);
    setShowRoutingConsentModal(false);
    setFemaleNyayGuideProfiles([]);
    setShowFemaleNyayGuidePanel(false);
  };

  const handleLawyerAccept = async (lawyer: LawyerProfile) => {
    const lawyerUid = lawyer.user_id || (lawyer as any).id;
    if (!lawyerCaseId || !lawyerUid) return;
    try {
      await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"}/api/lawyer/cases/${lawyerCaseId}/accept`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ lawyer_id: lawyerUid })
      });
      setMessages(prev => [...prev, {
        role: "assistant",
        content: `✅ **Connected with ${lawyer.name}!** You can continue the conversation in the chat window. Case ID: \`${lawyerCaseId}\`.`,
        agent: "lawyer_forwarder"
      }]);
    } catch (e) {
      console.error("Failed to accept lawyer case:", e);
    }
  };

  const handleLawyerReject = (lawyer: LawyerProfile) => {
    // Just update UI — no backend action needed for rejection
    console.log("Rejected lawyer:", lawyer.name);
  };

  const handleSubmit = async (e?: React.FormEvent, overrideQuery?: string): Promise<string | void> => {
    e?.preventDefault();
    
    // Manual submit terminates continuous conversation loop
    if (!overrideQuery) {
      isConversationActive.current = false;
    }
    
    let text = overrideQuery || query;
    if ((!text.trim() && selectedContexts.length === 0) || isLoading) return;

    if (selectedContexts.length > 0 && !overrideQuery) {
      text = `[Context: ${selectedContexts.join(", ")}] ${text}`;
    }

    setQuery("");
    setSelectedContexts([]);
    setStructuredReport(null);
    setSuggestedActions([]);
    setQuestionFlowActive(false);
    setCurrentPdfUrl(null);
    setCurrentCaseId(null);
    setShowRoutingConsentModal(false);
    setIsLoading(true);
    setIsInputCollapsed(true); // Collapse input after send
    currentAgentRef.current = null;
    displayAgentRef.current = null;

    if (messages.length >= MESSAGE_LIMIT * 2 && !user) {
      setShowAuthModal(true);
      return;
    }

    const userMessage = { role: "user" as const, content: text };
    const nextMessages = [...messages, userMessage];
    messagesSessionIdRef.current = localSessionId;
    setMessages(nextMessages);
    setActiveSessionId(localSessionId);
    upsertSessionInCache({
      id: localSessionId,
      session_data: nextMessages,
      updated_at: new Date().toISOString(),
    });
    updateHistoryCache(localSessionId, nextMessages);

    try {
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"}/chat/stream`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          query: text,
          user_id: userIdRef.current,
          user_name: user?.display_name || user?.email?.split("@")[0] || "User",
          location: userLocation,
          session_id: localSessionId,
          // Send last 6 messages (3 exchanges) as rolling context for the backend
          session_history: messages.slice(-6).map(m => ({ role: m.role, content: m.content }))
        }),
      });

      if (!response.ok) {
        const errText = await response.text().catch(() => "");
        throw new Error(`Chat stream failed: ${response.status} ${errText.slice(0, 200)}`);
      }
      if (!response.body) throw new Error("No response body");
      return await processStream(response.body.getReader());
    } catch (err) {
      console.error("Chat Error:", err);
      setMessages(prev => {
        const last = prev[prev.length - 1];
        if (last?.role === "assistant" && !last.content) {
          const next = [...prev];
          next[next.length - 1] = {
            ...last,
            content: "Sorry — I couldn’t get a response. Please try again.",
          };
          return next;
        }
        return [...prev, {
          role: "assistant",
          content: "Sorry — I couldn’t get a response. Please try again.",
        }];
      });
    } finally {
      setIsLoading(false);
    }
  };

  const handleAction = (action: any) => {
    handleSubmit(undefined, action.label || action.payload);
  };

  const handleChecklistSelect = (item: string) => {
    if (!selectedContexts.includes(item)) {
      setSelectedContexts(prev => [...prev, item]);
    }
  };

  const removeContext = (item: string) => {
    setSelectedContexts(prev => prev.filter(c => c !== item));
  };

  useEffect(() => {
    if (
      !isLoading &&
      messages.length > 0 &&
      user &&
      localSessionId &&
      messagesSessionIdRef.current === localSessionId
    ) {
      upsertSessionInCache({
        id: localSessionId,
        session_data: messages,
      });
      updateHistoryCache(localSessionId, messages);
      syncHistoryToBackend(user.uid, messages, localSessionId);
    }
    // upsertSessionInCache/updateHistoryCache are stable; omit from deps to avoid spurious reruns
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [messages, user, localSessionId, isLoading]);

  const syncHistoryToBackend = async (uid: string, history: Message[], sessionId: string) => {
    try {
      await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"}/api/chat/history`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          uid: uid,
          session_id: sessionId,
          session_data: history
        })
      });
    } catch (e) {
      console.error("Error syncing history:", e);
    }
  };

  const handleTranscription = async (text: string, mode: "dictation" | "conversation", languageCode?: string) => {
    if (mode === "dictation") {
      isConversationActive.current = false;
      setQuery(prev => prev + (prev.length > 0 ? " " : "") + text);
      setTimeout(() => textareaRef.current?.focus(), 100);
    } else {
      // Conversation mode
      isConversationActive.current = true;
      const finalAssistantResponse = await handleSubmit(undefined, text);
      
      if (finalAssistantResponse) {
        try {
          // Clean the text to remove markdown, brackets, urls
          const ttsText = cleanTTS(finalAssistantResponse);
          if (!ttsText) throw new Error("Narratable text is empty afte cleaning.");

          setIsPlayingTTS(true);
          
          // Play the response using Sarvam TTS proxy
          const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"}/api/synthesize`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ 
              text: ttsText,
              target_language_code: languageCode || "hi-IN" 
            })
          });
          
          if (!response.ok) {
            const errText = await response.text();
            throw new Error(`TTS generation failed: ${response.status} ${errText}`);
          }
          
          const rawBlob = await response.blob();
          if (rawBlob.size === 0) throw new Error("Received empty audio blob from TTS API");
          
          // Explicitly set the MIME type so the browser doesn't throw a NotSupportedError
          const audioBlob = new Blob([rawBlob], { type: "audio/mp3" });
          const audioUrl = URL.createObjectURL(audioBlob);
          const audio = new Audio(audioUrl);
          
          // Stop any previous audio before playing this one
          stopTTS();
          currentAudioRef.current = audio;
          
          audio.onended = () => {
             URL.revokeObjectURL(audioUrl); // Clean up memory
             currentAudioRef.current = null;
             setIsPlayingTTS(false);
             if (isConversationActive.current && voiceInputRef.current?.mode === "conversation") {
                voiceInputRef.current.startRecording();
             }
          };
          
          audio.onerror = (e) => {
             console.error("Audio playback error:", e, audio.error);
             currentAudioRef.current = null;
             setIsPlayingTTS(false);
             if (isConversationActive.current && voiceInputRef.current?.mode === "conversation") {
                voiceInputRef.current.startRecording();
             }
          };
          
          // Attempt to play (might require user interaction first, but mic click should suffice)
          await audio.play();
        } catch (e) {
          console.error("Audio synthesis/playback error:", e);
          setIsPlayingTTS(false);
          currentAudioRef.current = null;
          if (isConversationActive.current && voiceInputRef.current?.mode === "conversation") {
             voiceInputRef.current.startRecording();
          }
        }
      } else {
         // Auto-restart if there was no final text response but conversation is still active
         if (isConversationActive.current && voiceInputRef.current?.mode === "conversation") {
            voiceInputRef.current.startRecording();
         }
      }
    }
  };

  return (
    <div className="relative flex bg-white dark:bg-slate-900 h-full max-h-screen overflow-hidden font-sans text-slate-900 dark:text-slate-100 selection:bg-[#00634B]/20">

      {/* Side Console Panel */}
      {/* <AgentLog logs={logs} isOpen={isLogOpen} onToggle={() => setIsLogOpen(!isLogOpen)} /> */}

      {/* Main Chat Area */}
      <main className="flex-1 flex relative min-w-0 overflow-hidden">
        {/* Chat Column */}
        <div className={cn("flex flex-col relative flex-1")}>
        {!isCasesPage && (
          <Link
            href="/cases"
            title="Open Cases"
            className={cn(
              touchIconButton,
              "absolute top-4 left-4 z-50 bg-white border border-gray-100 dark:bg-slate-800 dark:border-slate-700 shadow-sm rounded-md text-gray-500 hover:text-[#00634B] hover:bg-gray-50 dark:hover:bg-slate-700/50 transition-[color,background-color] duration-150 ease-out motion-press-subtle md:h-10 md:w-10"
            )}
          >
            <Menu size={20} />
          </Link>
        )}

        <AuthModal
          isOpen={showAuthModal}
          onClose={() => setShowAuthModal(false)}
          onSuccess={(user, role) => {
            setShowAuthModal(false);
            // Re-sync logic is handled by useEffect on user/messages
            if (query) handleSubmit();
          }}
        />

        {/* Chat Stream */}
        <div
          className={cn(
            "relative flex min-h-0 flex-1 flex-col",
            isCasesPage && messages.length === 0 && "overflow-y-auto p-4 md:p-8 custom-scrollbar"
          )}
        >
          {isCasesPage && messages.length === 0 ? (
            <div className="mx-auto grid w-full flex-1 grid-rows-[minmax(0,1fr)_auto_minmax(0,1fr)]">
              <div aria-hidden />
              <div className="w-full">
                <CaseHomeLanding
                  disabled={isLoading}
                  onStartChat={(message) => void handleSubmit(undefined, message)}
                />
              </div>
              <div aria-hidden />
            </div>
          ) : messages.length === 0 ? (
            <div className="flex flex-1 flex-col overflow-y-auto p-4 md:p-8 custom-scrollbar">
              <div className="mx-auto flex w-full max-w-3xl flex-col items-center justify-center min-h-[60vh] animate-in fade-in zoom-in-95 duration-700">
                <div className="relative mb-8 flex h-24 w-24 items-center justify-center rounded-xl border-2 border-[#00634B]/10 bg-[#E6F0ED] p-4 shadow-xl shadow-[#00634B]/5 dark:bg-emerald-900/30">
                  <Image src="/3.png" alt="AI Assistant" fill className="object-contain p-4 dark:hidden" />
                  <Image src="/2.png" alt="AI Assistant" fill className="object-contain p-4 hidden dark:block" />
                </div>
                <h2 className="mb-4 text-center text-4xl font-black tracking-tight text-gray-900 dark:text-white">
                  How can I help you?
                </h2>
                <p className="mb-12 max-w-sm text-center text-lg text-gray-500 dark:text-gray-400">
                  Your AI Legal Expert for procedures, rights, and document assistance.
                </p>

                <div className="grid w-full grid-cols-1 gap-4 px-4 md:grid-cols-2">
                  {SUGGESTED_QUESTIONS.map((q, idx) => (
                    <button
                      key={idx}
                      onClick={() => handleSubmit(undefined, q.payload)}
                      className="group flex items-center gap-4 rounded-xl border border-gray-100 bg-white p-4 text-left shadow-sm motion-hover-card motion-press-subtle dark:border-slate-700 dark:bg-slate-800"
                    >
                      <div className="rounded-lg bg-gray-50 p-2 transition-colors group-hover:bg-[#E6F0ED] dark:bg-slate-700 dark:group-hover:bg-[#00634B]/20">
                        <q.icon className="h-5 w-5 text-gray-400 transition-colors group-hover:text-[#00634B] dark:text-gray-300 dark:group-hover:text-emerald-400" />
                      </div>
                      <span className="text-sm font-semibold text-gray-700 group-hover:text-gray-900 dark:text-gray-200 dark:group-hover:text-white">
                        {q.text}
                      </span>
                    </button>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            <CaseChatMessageList
              messages={messages}
              isLoading={isLoading}
              structuredReport={structuredReport}
              suggestedActions={suggestedActions}
              copiedIndex={copiedIndex}
              currentCasePending={currentCasePending}
              bottomPaddingClass={isInputCollapsed ? "pb-20" : "pb-48"}
              jumpButtonClassName={
                isInputCollapsed ? "bottom-16 sm:bottom-20" : "bottom-36 sm:bottom-40"
              }
              handleCopy={handleCopy}
              handleChecklistSelect={handleChecklistSelect}
              handleAction={handleAction}
              locationBanner={
                (resolvedLocation?.city || resolvedLocation?.state || userLocation || locationDenied) ? (
                  <div className="w-full">
                    <div className="inline-flex items-center gap-2 rounded-full border border-emerald-200/80 bg-emerald-50/90 px-3 py-1.5 text-xs font-semibold text-emerald-800 dark:border-emerald-800 dark:bg-emerald-950/50 dark:text-emerald-200">
                      <MapPin size={13} className="shrink-0" />
                      {resolvedLocation?.city || resolvedLocation?.state ? (
                        <span>
                          {[resolvedLocation.city, resolvedLocation.state].filter(Boolean).join(", ")}
                          {resolvedLocation.source === "user_area"
                            ? " · area shared"
                            : userLocation
                              ? " · GPS"
                              : ""}
                        </span>
                      ) : userLocation ? (
                        <span>Location shared (GPS)</span>
                      ) : (
                        <span>Location not shared — area may be requested in chat</span>
                      )}
                    </div>
                  </div>
                ) : undefined
              }
            />
          )}
        </div>

        {/* Floating restore button when input is collapsed */}
        {isInputCollapsed && !(isCasesPage && messages.length === 0) && (
          <div className="absolute bottom-5 left-1/2 -translate-x-1/2 z-30 animate-in fade-in slide-in-from-bottom-2 duration-300">
            <button
              onClick={() => {
                setIsInputCollapsed(false);
                setTimeout(() => textareaRef.current?.focus(), 100);
              }}
              className="flex items-center gap-2.5 bg-[#00634B] hover:bg-[#004D3C] text-white text-xs font-bold px-5 py-3 rounded-full shadow-2xl shadow-[#00634B]/30 motion-press group"
            >
              <MessageSquare size={15} className="group-hover:scale-110 transition-transform" />
              <span>Reply</span>
            </button>
          </div>
        )}

        {/* Floating Input Area */}
        <div
          className={cn(
            "absolute bottom-4 sm:bottom-8 left-0 right-0 px-3 sm:px-6 z-20 pointer-events-none flex justify-center",
            panelMotion,
            isInputCollapsed || (isCasesPage && messages.length === 0)
              ? "opacity-0 translate-y-8 pointer-events-none select-none"
              : "opacity-100 translate-y-0"
          )}
        >
          <div className="w-full max-w-4xl pointer-events-auto">
            <div className="relative flex flex-col gap-2 bg-white/95 dark:bg-slate-800/95 backdrop-blur-xl p-2 rounded-xl shadow-[0_30px_60px_-15px_rgba(0,0,0,0.15)] dark:shadow-none border border-gray-100 dark:border-slate-700 ring-1 ring-black/5 hover:ring-[#00634B]/20 transition-[box-shadow,ring-color] duration-200 ease-out">

              {/* Selected Context Badges */}
              {selectedContexts.length > 0 && (
                <div className="flex flex-wrap gap-2 px-4 pt-2 pb-1">
                  {selectedContexts.map((ctx, idx) => (
                    <div key={idx} className="flex items-center gap-1.5 bg-[#E6F0ED] text-[#00634B] border border-[#00634B]/10 px-3 py-1 rounded-full text-[10px] font-black tracking-widest uppercase">
                      <span>{ctx}</span>
                      <button
                        type="button"
                        onClick={() => removeContext(ctx)}
                        aria-label={`Remove ${ctx}`}
                        className="inline-flex min-h-11 min-w-11 items-center justify-center rounded-full hover:text-red-500 transition-colors md:min-h-0 md:min-w-0 md:h-auto md:w-auto"
                      >
                        ×
                      </button>
                    </div>
                  ))}
                </div>
              )}

              <div className="flex items-end gap-2 w-full px-2">
                <div className="pb-2.5 pl-2 flex items-center gap-1.5">
                  <div className={isPlayingTTS ? "opacity-30 pointer-events-none" : ""}>
                    <VoiceInput
                      ref={voiceInputRef}
                      onTranscription={handleTranscription}
                      isProcessing={isLoading}
                    />
                  </div>
                  {isPlayingTTS && (
                    <button
                      type="button"
                      onClick={stopTTS}
                      title="Stop Speaking"
                      className={cn(touchIconButton, "rounded-full bg-red-100 dark:bg-red-900/30 text-red-600 hover:bg-red-200 hover:scale-105 active:scale-95 transition-[transform,background-color] outline-none md:h-10 md:w-10")}
                    >
                      <div className="w-3.5 h-3.5 bg-red-600 dark:bg-red-500 rounded"></div>
                    </button>
                  )}
                  {/* Manual collapse button */}
                  {messages.length > 0 && (
                    <button
                      type="button"
                      onClick={() => setIsInputCollapsed(true)}
                      title="Collapse input"
                      className={cn(touchIconButtonCompact, "rounded-full text-gray-400 hover:text-[#00634B] hover:bg-[#E6F0ED] transition-[color,background-color]")}
                    >
                      <ChevronDown size={16} />
                    </button>
                  )}
                </div>

                <form
                  onSubmit={(e) => handleSubmit(e)}
                  className="flex-1 relative pb-2"
                >

                  <textarea
                    ref={textareaRef}
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        handleSubmit();
                      }
                    }}
                    placeholder={currentCasePending ? "Moderator review pending. You can still continue chatting..." : "Ask follow-up or provide details..."}
                    rows={1}
                    className="w-full bg-transparent border-0 focus:ring-0 focus:outline-none focus:border-0 focus-visible:ring-0 text-gray-800 dark:text-gray-200 placeholder:text-gray-400 dark:placeholder:text-gray-500 text-base py-3.5 pl-2 resize-none max-h-48 min-h-[48px] leading-relaxed transition-opacity duration-150 disabled:opacity-50"
                    disabled={isLoading}
                  />
                  <div className="absolute -bottom-1 left-2 text-[9px] text-gray-300 font-bold uppercase tracking-widest pointer-events-none">
                    Shift + Enter for new line • Enter to send {!user && `(${Math.floor(messages.length / 2)}/${MESSAGE_LIMIT})`}
                  </div>
                  <button
                    type="submit"
                    disabled={!query.trim() || isLoading}
                    className="absolute right-1 bottom-2 w-12 h-12 bg-[#00634B] text-white rounded-full hover:bg-[#004D3C] disabled:opacity-30 motion-press shadow-xl shadow-[#00634B]/20 flex items-center justify-center group"
                  >
                    <Send className="w-5 h-5 group-hover:translate-x-0.5 transition-transform" />
                  </button>
                </form>
              </div>
            </div>
            <div className="text-center mt-3 text-[10px] text-gray-400 font-black tracking-[0.2em] uppercase opacity-60">
              Verified AI Legal Intelligence
            </div>
          </div>
        </div>

        </div>

        {/* Lawyer Browser Split Panel — full-screen overlay on mobile */}
        {showLawyerPanel && recommendedLawyers.length > 0 && !showSahayakPanel && (
          <div className="fixed inset-0 z-50 bg-white dark:bg-slate-900 md:static md:inset-auto md:z-auto md:w-[min(420px,100%)] md:flex-shrink-0 md:h-full md:overflow-hidden md:border-l md:border-gray-100 dark:md:border-slate-700 animate-in slide-in-from-right-8 duration-500">
            <LawyerBrowserPanel
              lawyers={recommendedLawyers}
              lawyerCaseId={lawyerCaseId}
              onClose={() => setShowLawyerPanel(false)}
              onAccept={handleLawyerAccept}
              onReject={handleLawyerReject}
            />
          </div>
        )}

        {/* Sahayak Browser Split Panel — full-screen overlay on mobile */}
        {showSahayakPanel && (
          <div className="fixed inset-0 z-50 bg-white dark:bg-slate-900 md:static md:inset-auto md:z-auto md:w-[min(440px,100%)] md:flex-shrink-0 md:h-full md:overflow-hidden md:border-l md:border-gray-100 dark:md:border-slate-700 animate-in slide-in-from-right-8 duration-500">
            <SahayakBrowserPanel
              sahayaks={recommendedSahayaks}
              sahayakCaseId={sahayakCaseId}
              userId={user?.uid || ""}
              initialAcceptedId={acceptedSahayakId}
              onClose={() => { setShowSahayakPanel(false); setAcceptedSahayakId(null); }}
              onAccept={(uid, name) => {
                setAcceptedSahayakId(uid);
                setMessages(prev => [
                  ...prev,
                  { role: "assistant", content: `✅ You're now connected with **${name}**, your Nyay Guide! Open their profile to chat, or find them later under Find Help → Connected Sahayak.` }
                ]);
              }}
            />
          </div>
        )}

        {/* PDF Download Panel */}
        <PDFDownloadPanel caseId={currentCaseId ?? undefined} pdfUrl={currentPdfUrl} />

        {/* Nodal Guide Modal Panel */}
        {showNodalGuidePanel && (
          <NodalGuideBrowserPanel
            profiles={nodalGuideProfiles}
            caseId={currentCaseId}
            userId={user?.uid || ""}
            onConnect={(profile) => {
              setShowNodalGuidePanel(false);
              setMessages(prev => [
                ...prev,
                { role: "assistant", content: `✅ You're now connected with **${profile.name}** (Gram Nyayalaya Nodal Guide). They will contact you soon for in-person legal assistance. 🏛️` }
              ]);
            }}
            onClose={() => setShowNodalGuidePanel(false)}
          />
        )}

        {showRoutingConsentModal && routingRecommendation && (
          <RoutingConsentModal
            routing={routingRecommendation}
            onClose={() => setShowRoutingConsentModal(false)}
          />
        )}

        {showFemaleNyayGuidePanel && (
          <FemaleNyayGuidePanel
            profiles={femaleNyayGuideProfiles}
            caseId={currentCaseId}
            userId={user?.uid || ""}
            onConnect={(profile) => {
              setShowFemaleNyayGuidePanel(false);
              setMessages(prev => [
                ...prev,
                { role: "assistant", content: `✅ You're now connected with **${profile.name}** (Female NyayGuide).` }
              ]);
            }}
            onClose={() => setShowFemaleNyayGuidePanel(false)}
          />
        )}
      </main>
    </div>
  );
}
