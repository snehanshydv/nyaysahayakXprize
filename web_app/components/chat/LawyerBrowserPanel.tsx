"use client";

import { useMemo, useState } from "react";
import { X, ChevronLeft, ChevronRight } from "lucide-react";
import { LawyerListCard } from "@/components/lawyer/LawyerListCard";
import { LawyerProfileSheet } from "@/components/lawyer/LawyerProfileSheet";
import type { LawyerProfile } from "@/lib/lawyerTypes";
import { lawyerIdOf, normalizeLawyerProfile } from "@/lib/lawyerTypes";
import { useAuth } from "@/context/AuthContext";

export type { LawyerProfile };

const PAGE_SIZE = 5;

interface LawyerBrowserPanelProps {
  lawyers: LawyerProfile[];
  lawyerCaseId?: string | null;
  onClose: () => void;
  onAccept: (lawyer: LawyerProfile) => void | Promise<void>;
  onReject: (lawyer: LawyerProfile) => void;
}

export function LawyerBrowserPanel({
  lawyers,
  lawyerCaseId,
  onClose,
  onAccept,
  onReject,
}: LawyerBrowserPanelProps) {
  const { user, accessToken } = useAuth();
  const normalized = useMemo(
    () => (lawyers || []).map((l) => normalizeLawyerProfile(l as any)),
    [lawyers]
  );
  const [page, setPage] = useState(0);
  const [rejected, setRejected] = useState<Set<string>>(new Set());
  const [selected, setSelected] = useState<LawyerProfile | null>(null);
  const [sheetOpen, setSheetOpen] = useState(false);

  const available = normalized.filter((l) => !rejected.has(lawyerIdOf(l)));
  const pageCount = Math.max(1, Math.ceil(available.length / PAGE_SIZE));
  const safePage = Math.min(page, pageCount - 1);
  const pageItems = available.slice(safePage * PAGE_SIZE, safePage * PAGE_SIZE + PAGE_SIZE);

  const openProfile = (lawyer: LawyerProfile) => {
    setSelected(lawyer);
    setSheetOpen(true);
  };

  const handleReject = (lawyer: LawyerProfile) => {
    const id = lawyerIdOf(lawyer);
    setRejected((prev) => new Set([...prev, id]));
    onReject(lawyer);
    if (selected && lawyerIdOf(selected) === id) {
      setSheetOpen(false);
      setSelected(null);
    }
  };

  return (
    <div className="relative flex h-full flex-col bg-white dark:bg-slate-900 border-l border-gray-100 dark:border-slate-700 overflow-hidden">
      <div className="flex items-center justify-between px-4 sm:px-5 py-4 border-b border-gray-100 bg-gradient-to-r from-[#E6F0ED] to-white flex-shrink-0">
        <div>
          <h2 className="text-[15px] font-black text-[#00634B] tracking-tight">
            Matched lawyers
          </h2>
          <p className="text-xs text-gray-500 mt-0.5">
            {available.length} available · matched to your case category
          </p>
        </div>
        <button
          onClick={onClose}
          className="w-8 h-8 rounded-xl flex items-center justify-center text-gray-400 hover:text-gray-700 hover:bg-gray-100 transition-all"
        >
          <X size={16} />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-3 sm:p-4 space-y-2.5">
        {pageItems.length === 0 ? (
          <div className="flex h-full min-h-[160px] items-center justify-center text-center px-4">
            <p className="text-sm text-gray-500">No more lawyers in this list.</p>
          </div>
        ) : (
          pageItems.map((lawyer) => (
            <div key={lawyerIdOf(lawyer)} className="space-y-1.5">
              <LawyerListCard lawyer={lawyer} onClick={() => openProfile(lawyer)} />
              <button
                type="button"
                onClick={() => handleReject(lawyer)}
                className="w-full text-[11px] font-bold text-gray-400 hover:text-red-500 py-1"
              >
                Not a good fit
              </button>
            </div>
          ))
        )}
      </div>

      {available.length > PAGE_SIZE && (
        <div className="flex items-center justify-between px-4 py-3 border-t border-gray-100 bg-[#F8F9FA] flex-shrink-0">
          <button
            type="button"
            disabled={safePage <= 0}
            onClick={() => setPage((p) => Math.max(0, p - 1))}
            className="inline-flex items-center gap-1 text-xs font-bold text-[#00634B] disabled:opacity-30"
          >
            <ChevronLeft className="w-4 h-4" /> Prev
          </button>
          <span className="text-xs font-semibold text-gray-500">
            Page {safePage + 1} / {pageCount}
          </span>
          <button
            type="button"
            disabled={safePage >= pageCount - 1}
            onClick={() => setPage((p) => Math.min(pageCount - 1, p + 1))}
            className="inline-flex items-center gap-1 text-xs font-bold text-[#00634B] disabled:opacity-30"
          >
            Next <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      )}

      <LawyerProfileSheet
        open={sheetOpen}
        onClose={() => setSheetOpen(false)}
        lawyer={selected}
        accessToken={accessToken}
        currentUserId={user?.uid}
        lawyerCaseId={lawyerCaseId}
        onConnectLegacy={async (lawyer) => {
          await onAccept(lawyer);
        }}
      />
    </div>
  );
}
