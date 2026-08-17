"use client";

import React, { useState, useEffect } from "react";
import {
  MapPin,
  Phone,
  Mail,
  Star,
  X,
  Landmark,
  CheckCircle2,
  Globe,
  History,
  Loader2,
} from "lucide-react";


interface NodalGuideProfile {
  uid: string;
  name: string;
  location: string;
  occupation: string;
  bio: string;
  avatar: string;
  contact_number: string;
  email: string;
  availability: string;
  rating: number;
  cases_resolved: number;
  languages: string[];
}

interface Props {
  profiles: NodalGuideProfile[];
  caseId: string | null;
  userId: string;
  onConnect: (profile: NodalGuideProfile) => void;
  onClose: () => void;
}

const FALLBACK_AVATAR = "https://ui-avatars.com/api/?name=Nodal+Guide&background=2d5a4e&color=fff&size=128";

export function NodalGuideBrowserPanel({ profiles, caseId, userId, onConnect, onClose }: Props) {
  const guide = profiles[0] || null;
  const [connected, setConnected] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [imgSrc, setImgSrc] = useState<string>(guide?.avatar || FALLBACK_AVATAR);

  // Reset imgSrc if guide changes
  useEffect(() => {
    setImgSrc(guide?.avatar || FALLBACK_AVATAR);
  }, [guide?.avatar]);

  const handleConnect = async () => {
    if (!guide) return;
    setLoading(true);
    setError(null);
    try {
      // Reuse sahayak accept endpoint — same DB table, compatible schema
      if (caseId) {
        const baseUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";
        const res = await fetch(`${baseUrl}/api/sahayak/cases/${caseId}/accept`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            sahayak_uid: guide.uid,
            sahayak_name: guide.name,
            user_id: userId,
          }),
        });
        if (!res.ok) throw new Error("Failed to connect to Nodal Guide");
      }
      setConnected(true);
      onConnect(guide);
    } catch (e: any) {
      setError(e?.message || "Connection failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    /* ── Backdrop ── */
    <div
      className="nodal-guide-overlay"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      {/* ── Modal Card ── */}
      <div className="nodal-guide-modal">
        {/* Header */}
        <div className="ngp-header">
          <div className="ngp-header-icon">
            <Landmark size={22} />
          </div>
          <div>
            <h2 className="ngp-title">Gram Nyayalaya</h2>
            <p className="ngp-subtitle">Free Local Legal Assistance</p>
          </div>
          <button className="ngp-close-btn" onClick={onClose}>
            <X size={20} />
          </button>
        </div>

        {/* No profiles state */}
        {!guide ? (
          <div className="ngp-empty">
            <Landmark size={42} className="ngp-empty-icon" />
            <p>No Nodal Guide available in your area right now.</p>
            <p className="ngp-empty-sub">Please check back later or contact your district court.</p>
            <button className="ngp-btn-secondary" onClick={onClose}>Close</button>
          </div>
        ) : (
          <>
            {/* Guide Card */}
            <div className="ngp-guide-card">
              <div className="ngp-guide-avatar-wrap">
                {/* Plain <img> so onError fallback doesn't loop with next/image */}
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={imgSrc}
                  alt={guide.name}
                  width={88}
                  height={88}
                  className="ngp-guide-avatar"
                  onError={() => setImgSrc(FALLBACK_AVATAR)}
                />
                <span className={`ngp-availability-dot ${guide.availability === "Available" ? "available" : "busy"}`} />
              </div>

              <div className="ngp-guide-info">
                <h3 className="ngp-guide-name">{guide.name}</h3>
                <p className="ngp-guide-occupation">{guide.occupation || "Gram Nyayalaya Officer"}</p>

                <div className="ngp-guide-meta">
                  <span className="ngp-meta-item">
                    <MapPin size={13} /> {guide.location}
                  </span>
                  {guide.rating > 0 && (
                    <span className="ngp-meta-item">
                      <Star size={13} className="ngp-star" /> {guide.rating.toFixed(1)}
                    </span>
                  )}
                  {guide.cases_resolved > 0 && (
                    <span className="ngp-meta-item">
                      <History size={13} /> {guide.cases_resolved} cases
                    </span>
                  )}
                </div>

                {guide.bio && <p className="ngp-guide-bio">{guide.bio}</p>}

                <div className="ngp-contact-row">
                  {guide.contact_number && (
                    <a href={`tel:${guide.contact_number}`} className="ngp-contact-chip">
                      <Phone size={13} /> {guide.contact_number}
                    </a>
                  )}
                  {guide.email && (
                    <a href={`mailto:${guide.email}`} className="ngp-contact-chip">
                      <Mail size={13} /> Email
                    </a>
                  )}
                </div>

                {guide.languages?.length > 0 && (
                  <div className="ngp-lang-row">
                    <Globe size={13} />
                    {guide.languages.map((l) => (
                      <span key={l} className="ngp-lang-chip">{l}</span>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Info banner */}
            <div className="ngp-info-banner">
              <Landmark size={15} />
              <span>
                Gram Nyayalayas provide <strong>free</strong> legal assistance at the grassroots level.
                Your guide can visit your location if needed.
              </span>
            </div>

            {/* Error */}
            {error && <p className="ngp-error">{error}</p>}

            {/* CTA */}
            {connected ? (
              <div className="ngp-connected-msg">
                <CheckCircle2 size={20} />
                <span>Connected! <strong>{guide.name}</strong> will contact you shortly.</span>
              </div>
            ) : (
              <button
                className="ngp-connect-btn"
                onClick={handleConnect}
                disabled={loading}
              >
                {loading ? (
                  <><Loader2 size={18} className="ngp-spinner" /> Connecting…</>
                ) : (
                  <><Landmark size={18} /> Connect with Nodal Guide</>
                )}
              </button>
            )}
          </>
        )}
      </div>

      <style>{`
        .nodal-guide-overlay {
          position: fixed;
          inset: 0;
          z-index: 9999;
          display: flex;
          align-items: center;
          justify-content: center;
          background: rgba(0, 0, 0, 0.55);
          backdrop-filter: blur(8px);
          -webkit-backdrop-filter: blur(8px);
          animation: ngpFadeIn 0.2s ease;
        }
        @keyframes ngpFadeIn {
          from { opacity: 0; }
          to   { opacity: 1; }
        }
        .nodal-guide-modal {
          background: linear-gradient(145deg, #1a2e28, #0f1f1b);
          border: 1px solid rgba(78, 160, 120, 0.25);
          border-radius: 20px;
          padding: 0;
          width: min(520px, 95vw);
          max-height: 92vh;
          overflow-y: auto;
          box-shadow: 0 28px 80px rgba(0,0,0,0.6), 0 0 0 1px rgba(78,160,120,0.1);
          animation: ngpSlideUp 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        @keyframes ngpSlideUp {
          from { transform: translateY(30px) scale(0.96); opacity: 0; }
          to   { transform: translateY(0) scale(1); opacity: 1; }
        }
        .ngp-header {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 20px 24px 16px;
          border-bottom: 1px solid rgba(255,255,255,0.07);
        }
        .ngp-header-icon {
          width: 42px;
          height: 42px;
          border-radius: 10px;
          background: linear-gradient(135deg, #2d8a5e, #1d6044);
          display: flex;
          align-items: center;
          justify-content: center;
          color: #a8f0d0;
          flex-shrink: 0;
        }
        .ngp-title {
          font-size: 16px;
          font-weight: 700;
          color: #e8f5f0;
          margin: 0;
          line-height: 1.2;
        }
        .ngp-subtitle {
          font-size: 12px;
          color: #6db890;
          margin: 2px 0 0;
        }
        .ngp-close-btn {
          margin-left: auto;
          background: rgba(255,255,255,0.06);
          border: none;
          color: #8ba99e;
          border-radius: 8px;
          width: 34px;
          height: 34px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: background 0.15s, color 0.15s;
        }
        .ngp-close-btn:hover { background: rgba(255,255,255,0.12); color: #e0f0ea; }

        .ngp-guide-card {
          display: flex;
          gap: 20px;
          padding: 22px 24px;
          align-items: flex-start;
        }
        .ngp-guide-avatar-wrap {
          position: relative;
          flex-shrink: 0;
        }
        .ngp-guide-avatar {
          width: 88px;
          height: 88px;
          border-radius: 14px;
          object-fit: cover;
          border: 2px solid rgba(78,160,120,0.3);
        }
        .ngp-availability-dot {
          position: absolute;
          bottom: 5px;
          right: 5px;
          width: 11px;
          height: 11px;
          border-radius: 50%;
          border: 2px solid #1a2e28;
        }
        .ngp-availability-dot.available { background: #4ade80; }
        .ngp-availability-dot.busy      { background: #f59e0b; }

        .ngp-guide-info { flex: 1; min-width: 0; }
        .ngp-guide-name {
          font-size: 17px;
          font-weight: 700;
          color: #e8f5f0;
          margin: 0 0 3px;
        }
        .ngp-guide-occupation {
          font-size: 13px;
          color: #6db890;
          margin: 0 0 10px;
        }
        .ngp-guide-meta {
          display: flex;
          flex-wrap: wrap;
          gap: 10px;
          margin-bottom: 10px;
        }
        .ngp-meta-item {
          display: flex;
          align-items: center;
          gap: 4px;
          font-size: 12px;
          color: #8ba99e;
        }
        .ngp-star { color: #f59e0b; }
        .ngp-guide-bio {
          font-size: 13px;
          color: #a0c4b4;
          line-height: 1.5;
          margin: 0 0 10px;
          display: -webkit-box;
          -webkit-line-clamp: 3;
          -webkit-box-orient: vertical;
          overflow: hidden;
        }
        .ngp-contact-row {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
          margin-bottom: 8px;
        }
        .ngp-contact-chip {
          display: flex;
          align-items: center;
          gap: 5px;
          padding: 5px 10px;
          background: rgba(78,160,120,0.1);
          border: 1px solid rgba(78,160,120,0.2);
          border-radius: 20px;
          font-size: 12px;
          color: #7ec9a6;
          text-decoration: none;
          transition: background 0.15s;
        }
        .ngp-contact-chip:hover { background: rgba(78,160,120,0.18); }
        .ngp-lang-row {
          display: flex;
          align-items: center;
          gap: 6px;
          color: #6b8f80;
          font-size: 12px;
          flex-wrap: wrap;
        }
        .ngp-lang-chip {
          background: rgba(255,255,255,0.05);
          border: 1px solid rgba(255,255,255,0.08);
          border-radius: 12px;
          padding: 2px 8px;
          font-size: 11px;
          color: #8ba99e;
        }
        .ngp-info-banner {
          margin: 0 24px 18px;
          padding: 12px 16px;
          background: rgba(78,160,120,0.08);
          border: 1px solid rgba(78,160,120,0.18);
          border-radius: 12px;
          display: flex;
          align-items: flex-start;
          gap: 10px;
          font-size: 13px;
          color: #8dbbaa;
          line-height: 1.5;
        }
        .ngp-info-banner svg { color: #4ead7e; flex-shrink: 0; margin-top: 1px; }
        .ngp-info-banner strong { color: #a8d4bc; }

        .ngp-error {
          margin: 0 24px 12px;
          padding: 10px 14px;
          background: rgba(239,68,68,0.1);
          border: 1px solid rgba(239,68,68,0.2);
          border-radius: 10px;
          color: #fca5a5;
          font-size: 13px;
        }
        .ngp-connect-btn {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 10px;
          margin: 0 24px 24px;
          width: calc(100% - 48px);
          padding: 14px 20px;
          background: linear-gradient(135deg, #2d8a5e, #1d6044);
          border: none;
          border-radius: 12px;
          color: #c8f0de;
          font-size: 15px;
          font-weight: 600;
          cursor: pointer;
          transition: opacity 0.15s, transform 0.1s;
        }
        .ngp-connect-btn:hover:not(:disabled) { opacity: 0.9; transform: translateY(-1px); }
        .ngp-connect-btn:disabled { opacity: 0.6; cursor: not-allowed; }
        .ngp-spinner { animation: spin 0.9s linear infinite; }
        @keyframes spin { to { transform: rotate(360deg); } }

        .ngp-connected-msg {
          display: flex;
          align-items: center;
          gap: 10px;
          margin: 0 24px 24px;
          padding: 14px 18px;
          background: rgba(74,222,128,0.1);
          border: 1px solid rgba(74,222,128,0.25);
          border-radius: 12px;
          color: #86efac;
          font-size: 14px;
        }
        .ngp-empty {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 10px;
          padding: 40px 24px 28px;
          color: #6b8f80;
          text-align: center;
          font-size: 14px;
        }
        .ngp-empty-icon { color: #2d5a4e; }
        .ngp-empty-sub { font-size: 12px; color: #4a6b5e; }
        .ngp-btn-secondary {
          margin-top: 10px;
          padding: 10px 24px;
          background: rgba(255,255,255,0.05);
          border: 1px solid rgba(255,255,255,0.1);
          border-radius: 10px;
          color: #8ba99e;
          font-size: 14px;
          cursor: pointer;
          transition: background 0.15s;
        }
        .ngp-btn-secondary:hover { background: rgba(255,255,255,0.1); }
      `}</style>
    </div>
  );
}
