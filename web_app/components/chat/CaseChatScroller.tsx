"use client";

import { type ReactNode, useEffect, useRef, useState } from "react";
import {
  MessageScroller,
  MessageScrollerContent,
  MessageScrollerProvider,
  MessageScrollerViewport,
} from "@/components/ui/message-scroller";
import { CaseChatJumpButton } from "@/components/chat/CaseChatJumpButton";
import { cn } from "@/lib/utils";

type CaseChatScrollerProps = {
  children: ReactNode;
  className?: string;
  contentClassName?: string;
  /** Follow live edge after the reader clicks jump-to-latest. */
  autoScroll?: boolean;
  isStreaming?: boolean;
  scrollPreviousItemPeek?: number;
  jumpButtonClassName?: string;
};

export function CaseChatScroller({
  children,
  className,
  contentClassName,
  autoScroll = false,
  isStreaming = false,
  scrollPreviousItemPeek = 64,
  jumpButtonClassName,
}: CaseChatScrollerProps) {
  const [followLive, setFollowLive] = useState(false);
  const wasStreamingRef = useRef(false);

  // New stream → anchor the turn; re-enable follow only when the reader asks.
  useEffect(() => {
    if (isStreaming && !wasStreamingRef.current) {
      setFollowLive(false);
    }
    wasStreamingRef.current = isStreaming;
  }, [isStreaming]);

  return (
    <MessageScrollerProvider
      autoScroll={autoScroll || followLive}
      defaultScrollPosition="last-anchor"
      scrollPreviousItemPeek={scrollPreviousItemPeek}
    >
      <MessageScroller className={cn("relative flex min-h-0 flex-1 flex-col", className)}>
        <MessageScrollerViewport
          className={cn(
            "custom-scrollbar scroll-fade-b px-4 md:px-8",
            className
          )}
        >
          <MessageScrollerContent
            aria-busy={isStreaming}
            className={cn("mx-auto w-full max-w-3xl gap-8 py-1", contentClassName)}
          >
            {children}
          </MessageScrollerContent>
        </MessageScrollerViewport>

        <CaseChatJumpButton
          onFollowLive={() => setFollowLive(true)}
          className={cn("bottom-36 sm:bottom-40", jumpButtonClassName)}
        />
      </MessageScroller>
    </MessageScrollerProvider>
  );
}
