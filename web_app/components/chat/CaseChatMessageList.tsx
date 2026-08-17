"use client";

import { type ReactNode } from "react";
import { ShieldAlert } from "lucide-react";
import { MessageScrollerItem } from "@/components/ui/message-scroller";
import { Marker, MarkerContent, MarkerIcon } from "@/components/ui/marker";
import { CaseChatMessage, type CaseChatMessageData } from "@/components/chat/CaseChatMessage";
import { CaseChatScroller } from "@/components/chat/CaseChatScroller";
import { CaseThinkingIndicator } from "@/components/chat/CaseThinkingIndicator";
import { cn } from "@/lib/utils";

type CaseChatMessageListProps = {
  messages: CaseChatMessageData[];
  isLoading: boolean;
  structuredReport: any;
  suggestedActions: any[];
  copiedIndex: number | null;
  currentCasePending: boolean;
  locationBanner?: React.ReactNode;
  bottomPaddingClass?: string;
  jumpButtonClassName?: string;
  handleCopy: (text: string, index: number) => void;
  handleChecklistSelect: (item: string) => void;
  handleAction: (action: any) => void;
};

export function CaseChatMessageList({
  messages,
  isLoading,
  structuredReport,
  suggestedActions,
  copiedIndex,
  currentCasePending,
  locationBanner,
  bottomPaddingClass,
  jumpButtonClassName,
  handleCopy,
  handleChecklistSelect,
  handleAction,
}: CaseChatMessageListProps) {
  const showThinking =
    isLoading && messages.length > 0 && messages[messages.length - 1]?.role === "user";

  return (
    <CaseChatScroller
      isStreaming={isLoading}
      contentClassName={cn(bottomPaddingClass)}
      jumpButtonClassName={jumpButtonClassName}
    >
      {locationBanner}

      {messages.map((msg, i) => (
        <MessageScrollerItem
          key={`msg-${i}`}
          messageId={`msg-${i}`}
          scrollAnchor={msg.role === "user"}
        >
          <CaseChatMessage
            msg={msg}
            index={i}
            isLast={i === messages.length - 1}
            isNew={i >= messages.length - 2}
            isStreaming={isLoading && i === messages.length - 1 && msg.role === "assistant"}
            structuredReport={structuredReport}
            suggestedActions={suggestedActions}
            copiedIndex={copiedIndex}
            handleCopy={handleCopy}
            handleChecklistSelect={handleChecklistSelect}
            handleAction={handleAction}
          />
        </MessageScrollerItem>
      ))}

      {showThinking && (
        <MessageScrollerItem messageId="thinking">
          <CaseThinkingIndicator />
        </MessageScrollerItem>
      )}

      {currentCasePending && (
        <MessageScrollerItem messageId="moderator-pending">
          <Marker variant="border" className="rounded-xl border-amber-200/80 bg-amber-50/70 px-4 py-3 dark:border-amber-900/60 dark:bg-amber-950/20">
            <MarkerIcon className="text-amber-600">
              <ShieldAlert className="size-4" />
            </MarkerIcon>
            <MarkerContent className="text-left">
              <span className="block text-sm font-semibold text-amber-900 dark:text-amber-300">
                Pending moderator review
              </span>
              <span className="mt-0.5 block text-xs leading-relaxed text-amber-800/90 dark:text-amber-200/90">
                A legal moderator is reviewing this case. You can keep chatting while review is in
                progress.
              </span>
            </MarkerContent>
          </Marker>
        </MessageScrollerItem>
      )}

      <div className="h-4 shrink-0" aria-hidden />
    </CaseChatScroller>
  );
}
