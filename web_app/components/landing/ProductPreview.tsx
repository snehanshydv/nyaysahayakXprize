"use client";

import Image from "next/image";
import { motion } from "framer-motion";
import { Mic, Send, Shield } from "lucide-react";
import { dmSans, instrumentSerif } from "@/lib/fonts";
import { EASE_OUT } from "@/lib/motion";
import { cn } from "@/lib/utils";

/**
 * Synthetic product chrome for the marketing hero.
 * Demonstrates routing + rights + human handoff — not a live session.
 */
export function ProductPreview({ reduceMotion = false }: { reduceMotion?: boolean }) {
  const enter = reduceMotion
    ? { initial: false as const }
    : {
        initial: { opacity: 0, y: 20 },
        animate: { opacity: 1, y: 0 },
        transition: { duration: 0.65, ease: EASE_OUT, delay: 0.12 },
      };

  const chipEnter = (delay: number, x: number, y: number) =>
    reduceMotion
      ? { initial: false as const }
      : {
          initial: { opacity: 0, x, y },
          animate: { opacity: 1, x: 0, y: 0 },
          transition: { duration: 0.55, delay, ease: EASE_OUT },
        };

  return (
    <div className="relative mx-auto w-full max-w-lg lg:max-w-none">
      <motion.div
        {...enter}
        className="relative rounded-xl border border-slate-200/80 bg-white p-1 shadow-[0_24px_60px_-24px_rgba(0,99,75,0.18),0_8px_24px_-12px_rgba(15,23,42,0.08)]"
      >
        <div className="flex items-center gap-2 border-b border-slate-100 px-3 py-2.5">
          <div className="flex gap-1.5" aria-hidden>
            <span className="h-2.5 w-2.5 rounded-full bg-slate-200" />
            <span className="h-2.5 w-2.5 rounded-full bg-slate-200" />
            <span className="h-2.5 w-2.5 rounded-full bg-slate-200" />
          </div>
          <span className={cn(dmSans.className, "ml-2 text-[11px] font-medium text-slate-400")}>
            app.nyaysahayak.in/cases
          </span>
          <span className="ml-auto rounded-md bg-slate-50 px-1.5 py-0.5 text-[9px] font-medium uppercase tracking-wide text-slate-400">
            Preview
          </span>
        </div>

        <div className={cn(dmSans.className, "space-y-3.5 p-4 sm:p-5")}>
          <div className="text-center">
            <div className="mx-auto mb-3 flex h-10 w-10 items-center justify-center rounded-lg border border-slate-100 bg-white shadow-sm">
              <Image src="/2.png" alt="" width={24} height={24} className="object-contain" />
            </div>
            <p className={cn(instrumentSerif.className, "text-lg text-slate-900 sm:text-xl")}>
              You deserve to be heard
            </p>
            <p className="mx-auto mt-1.5 max-w-xs text-xs leading-relaxed text-slate-500">
              Share what happened. We route you to the right path under Indian law.
            </p>
          </div>

          {/* Synthetic user message */}
          <div className="ml-auto max-w-[90%] rounded-lg rounded-br-sm bg-[#00634B] px-3 py-2 text-left">
            <p className="text-[11px] leading-relaxed text-white">
              Someone took money from my UPI after a fake bank call…
            </p>
          </div>

          {/* Synthetic assistant response */}
          <div className="max-w-[95%] space-y-2 rounded-lg rounded-bl-sm border border-slate-200/80 bg-[#F8F9FA]/80 px-3 py-2.5 text-left">
            <p className="text-[10px] font-semibold uppercase tracking-wide text-[#00634B]">
              Routed · Cyber specialist
            </p>
            <p className="text-[11px] leading-relaxed text-slate-600">
              This looks like online fraud. You can report on cybercrime.gov.in, dial 1930, and keep
              SMS/UPI screenshots as evidence. Want a Zero FIR checklist next?
            </p>
            <div className="flex flex-wrap gap-1.5 pt-0.5">
              <span className="rounded-md border border-slate-200 bg-white px-2 py-0.5 text-[10px] font-medium text-slate-600">
                Evidence checklist
              </span>
              <span className="rounded-md border border-emerald-200 bg-emerald-50/80 px-2 py-0.5 text-[10px] font-medium text-[#00634B]">
                Connect Nyay Guide
              </span>
              <span className="rounded-md border border-slate-200 bg-white px-2 py-0.5 text-[10px] font-medium text-slate-600">
                Find a lawyer
              </span>
            </div>
          </div>

          <div className="rounded-lg border border-emerald-100 bg-white p-2.5 shadow-sm ring-1 ring-emerald-500/10">
            <div className="flex items-center gap-2">
              <div className="min-h-[36px] flex-1 rounded-md bg-slate-50/80 px-2.5 py-2 text-left text-[11px] text-slate-400">
                Describe your legal issue…
              </div>
              <span className="inline-flex h-8 w-8 items-center justify-center rounded-md border border-slate-200 text-slate-500" aria-hidden>
                <Mic className="h-3.5 w-3.5" />
              </span>
              <span className="inline-flex h-8 items-center gap-1 rounded-md bg-[#00634B] px-2.5 text-[10px] font-semibold text-white">
                <Send className="h-3 w-3" />
                Send
              </span>
            </div>
          </div>
        </div>
      </motion.div>

      <motion.div
        {...chipEnter(0.4, 14, 8)}
        className={cn(
          dmSans.className,
          "absolute -right-2 top-10 hidden rounded-lg border border-slate-200/80 bg-white px-3 py-2.5 shadow-md sm:block lg:-right-5"
        )}
      >
        <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">Grounded guidance</p>
        <p className="mt-0.5 text-xs font-medium text-slate-800">IT Act · cybercrime.gov.in</p>
      </motion.div>

      <motion.div
        {...chipEnter(0.5, -14, 10)}
        className={cn(
          dmSans.className,
          "absolute -left-2 bottom-20 hidden rounded-lg border border-slate-200/80 bg-white px-3 py-2.5 shadow-md sm:block lg:-left-5"
        )}
      >
        <div className="flex items-center gap-2">
          <Shield className="h-4 w-4 text-[#00634B]" aria-hidden />
          <div>
            <p className="text-xs font-semibold text-slate-800">Human ladder</p>
            <p className="text-[10px] text-slate-500">Guide · Lawyer when ready</p>
          </div>
        </div>
      </motion.div>

      <motion.div
        {...chipEnter(0.58, 8, 12)}
        className={cn(
          dmSans.className,
          "absolute -bottom-2 right-6 hidden rounded-lg border border-amber-200 bg-amber-50 px-2.5 py-1.5 shadow-sm sm:block"
        )}
      >
        <p className="text-[10px] font-semibold text-amber-950">Also: dial 1930 if urgent</p>
      </motion.div>
    </div>
  );
}
