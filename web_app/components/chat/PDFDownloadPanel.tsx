"use client";

import { useState, useEffect } from "react";
import { Download, ChevronDown, CheckCircle } from "lucide-react";

interface PDFDownloadPanelProps {
    caseId?: string;
    pdfUrl?: string | null;
    onPDFReady?: (url: string) => void;
}

export function PDFDownloadPanel({ caseId, pdfUrl: initialPdfUrl, onPDFReady }: PDFDownloadPanelProps) {
    const [isExpanded, setIsExpanded] = useState(false);

    // Notify parent when PDF is available
    useEffect(() => {
        if (initialPdfUrl) {
            onPDFReady?.(initialPdfUrl);
        }
    }, [initialPdfUrl, onPDFReady]);
    
    const handleDownload = () => {
        const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";
        const endpointUrl = caseId ? `${API_URL}/api/cases/${encodeURIComponent(caseId)}/pdf` : null;
        const targetUrl = endpointUrl || initialPdfUrl;
        if (targetUrl) {
            window.open(targetUrl, "_blank");
        }
    };
    
    // Don't show if no case context or no PDF ready yet
    if (!caseId) return null;
    if (!initialPdfUrl) return null;
    
    return (
        <div className="fixed bottom-4 right-4 z-40 max-w-xs">
            {/* Main Panel */}
            <div className="bg-white dark:bg-slate-900 rounded-lg shadow-lg border border-slate-200 dark:border-slate-800">
                {/* Header */}
                <button
                    onClick={() => setIsExpanded(!isExpanded)}
                    className="w-full px-4 py-3 flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
                >
                    <div className="flex items-center gap-2">
                        <CheckCircle className="w-5 h-5 text-green-500" />
                        <span className="font-medium text-slate-900 dark:text-slate-100">
                            Case Document Ready
                        </span>
                    </div>
                    <ChevronDown
                        className={`w-4 h-4 transition-transform ${isExpanded ? "rotate-180" : ""}`}
                    />
                </button>

                {/* Expanded Content */}
                {isExpanded && (
                    <div className="px-4 py-3 border-t border-slate-200 dark:border-slate-800 space-y-3">
                        <p className="text-sm text-slate-600 dark:text-slate-400">
                            Your comprehensive case report with all collected information is ready for download.
                        </p>
                        
                        <button
                            onClick={handleDownload}
                            className="w-full flex items-center justify-center gap-2 px-3 py-2 bg-green-600 hover:bg-green-700 text-white rounded-md transition-colors font-medium text-sm"
                        >
                            <Download className="w-4 h-4" />
                            Download PDF
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
}
