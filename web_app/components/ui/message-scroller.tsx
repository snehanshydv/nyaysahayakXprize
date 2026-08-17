"use client";

import * as React from "react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { ArrowDownIcon } from "lucide-react";

type ScrollOptions = { behavior?: ScrollBehavior };

type MessageScrollerContextType = {
  viewportRef: React.RefObject<HTMLDivElement | null>;
  scrollToBottom: (options?: ScrollOptions) => void;
  scrollToEnd: (options?: ScrollOptions) => void;
  scrollToStart: (options?: ScrollOptions) => void;
  canScrollDown: boolean;
  canScrollUp: boolean;
};

const MessageScrollerContext = React.createContext<MessageScrollerContextType>({
  viewportRef: { current: null },
  scrollToBottom: () => {},
  scrollToEnd: () => {},
  scrollToStart: () => {},
  canScrollDown: false,
  canScrollUp: false,
});

export function useMessageScroller() {
  return React.useContext(MessageScrollerContext);
}

export function useMessageScrollerScrollable() {
  const { canScrollDown, canScrollUp } = useMessageScroller();
  return { start: canScrollUp, end: canScrollDown };
}

export function useMessageScrollerVisibility() {
  const { canScrollDown, canScrollUp } = useMessageScroller();
  return { start: canScrollUp, end: canScrollDown };
}

export function MessageScrollerProvider({
  children,
  autoScroll,
}: {
  children?: React.ReactNode;
  autoScroll?: boolean;
  defaultScrollPosition?: string;
  scrollPreviousItemPeek?: number;
}) {
  const viewportRef = React.useRef<HTMLDivElement>(null);
  const [canScrollDown, setCanScrollDown] = React.useState(false);
  const [canScrollUp, setCanScrollUp] = React.useState(false);

  const checkScroll = React.useCallback(() => {
    const el = viewportRef.current;
    if (!el) return;
    const threshold = 20;
    const hasMoreDown = el.scrollHeight - el.scrollTop - el.clientHeight > threshold;
    const hasMoreUp = el.scrollTop > threshold;
    setCanScrollDown(hasMoreDown);
    setCanScrollUp(hasMoreUp);
  }, []);

  const scrollToEnd = React.useCallback((options?: ScrollOptions) => {
    if (viewportRef.current) {
      viewportRef.current.scrollTo({
        top: viewportRef.current.scrollHeight,
        behavior: options?.behavior || "smooth",
      });
    }
  }, []);

  const scrollToStart = React.useCallback((options?: ScrollOptions) => {
    if (viewportRef.current) {
      viewportRef.current.scrollTo({
        top: 0,
        behavior: options?.behavior || "smooth",
      });
    }
  }, []);

  React.useEffect(() => {
    if (autoScroll) {
      scrollToEnd({ behavior: "smooth" });
    }
  }, [autoScroll, scrollToEnd]);

  return (
    <MessageScrollerContext.Provider
      value={{
        viewportRef,
        scrollToBottom: scrollToEnd,
        scrollToEnd,
        scrollToStart,
        canScrollDown,
        canScrollUp,
      }}
    >
      {children}
    </MessageScrollerContext.Provider>
  );
}

export function MessageScroller({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      data-slot="message-scroller"
      className={cn("group/message-scroller relative flex size-full min-h-0 flex-col overflow-hidden", className)}
      {...props}
    >
      {children}
    </div>
  );
}

export function MessageScrollerViewport({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  const { viewportRef } = useMessageScroller();

  return (
    <div
      ref={viewportRef}
      data-slot="message-scroller-viewport"
      className={cn(
        "size-full min-h-0 min-w-0 scrollbar-thin overflow-y-auto overscroll-contain",
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
}

export function MessageScrollerContent({
  className,
  children,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      data-slot="message-scroller-content"
      className={cn("flex h-max min-h-full flex-col gap-6", className)}
      {...props}
    >
      {children}
    </div>
  );
}

export function MessageScrollerItem({
  className,
  children,
  messageId,
  scrollAnchor,
  ...props
}: React.HTMLAttributes<HTMLDivElement> & { messageId?: string; scrollAnchor?: boolean }) {
  return (
    <div
      data-slot="message-scroller-item"
      data-message-id={messageId}
      className={cn("min-w-0 shrink-0 overflow-visible", className)}
      {...props}
    >
      {children}
    </div>
  );
}

export function MessageScrollerButton({
  direction = "end",
  className,
  children,
  variant = "secondary",
  size = "icon-sm",
  onClick,
  render,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  direction?: "start" | "end";
  variant?: any;
  size?: any;
  render?: any;
}) {
  const { scrollToEnd, scrollToStart } = useMessageScroller();

  return (
    <Button
      variant={variant}
      size={size as any}
      onClick={(e) => {
        if (direction === "end") {
          scrollToEnd({ behavior: "smooth" });
        } else {
          scrollToStart({ behavior: "smooth" });
        }
        onClick?.(e);
      }}
      className={cn("absolute bottom-4 left-1/2 -translate-x-1/2 z-10 shadow-md", className)}
      {...props}
    >
      {children ?? (
        <>
          <ArrowDownIcon className="size-4" />
          <span className="sr-only">
            {direction === "end" ? "Scroll to end" : "Scroll to start"}
          </span>
        </>
      )}
    </Button>
  );
}
