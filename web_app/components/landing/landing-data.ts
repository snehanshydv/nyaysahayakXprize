import {
  BookOpen,
  Briefcase,
  FileText,
  Globe,
  Lock,
  Map,
  Scale,
  Search,
  Shield,
  ShieldCheck,
  Users,
  type LucideIcon,
} from "lucide-react";

export const NAV_LINKS = [
  { label: "How it works", href: "#how-it-works" },
  { label: "Human help", href: "#human-help" },
  { label: "FAQ", href: "#faq" },
] as const;

/** Public tools — usable without an account. */
export const EXPLORE_TOOLS: {
  title: string;
  desc: string;
  href: string;
  icon: LucideIcon;
}[] = [
  {
    title: "Scam heatmap",
    desc: "See where civil and cyber scams are being reported across India.",
    href: "/scam-heatmap",
    icon: Map,
  },
  {
    title: "Find a lawyer",
    desc: "Browse verified lawyers and Nyay Guides by practice area and location.",
    href: "/find-help",
    icon: Users,
  },
  {
    title: "Search articles",
    desc: "Look up plain-language guidance on rights, procedures, and everyday disputes.",
    href: "/search",
    icon: Search,
  },
  {
    title: "Legal library",
    desc: "Read rights explainers — FIR, consumer, cyber fraud, and more — before you start a case.",
    href: "/legal-rights",
    icon: BookOpen,
  },
];


/** Defensible trust claims — no blanket “human verified” certification. */
export const TRUST_ITEMS = [
  { icon: Globe, label: "Built for Indian citizens" },
  { icon: Scale, label: "Guidance, not a law firm" },
  { icon: Lock, label: "Private by default" },
  { icon: Users, label: "Human help when it matters" },
  { icon: BookOpen, label: "Grounded in Indian law & procedure" },
] as const;

export const HOW_IT_WORKS = [
  {
    step: "Describe your situation",
    detail: "In your own words — voice or text. No legal jargon required.",
    example: "“Someone took money from my UPI after a fake bank call.”",
  },
  {
    step: "AI routes to the right path",
    detail: "A supervisor sends you to a specialist flow — cyber, civil, criminal, domestic, scam, or documents.",
    example: "Routed to Cyber · scam / UPI fraud path",
  },
  {
    step: "Know your rights",
    detail: "Plain-language options grounded in Indian law and procedure — not generic chatbot advice.",
    example: "Zero FIR · cybercrime.gov.in · what to save as evidence",
  },
  {
    step: "Drafts, templates & evidence",
    detail: "Attach screenshots and records. Get help drafting complaints and notices you can review.",
    example: "FIR draft · evidence checklist",
  },
  {
    step: "Structured case report",
    detail: "Your story stays together — so you never re-explain from scratch.",
    example: "Case summary ready for a human helper",
  },
  {
    step: "Human help when you need it",
    detail: "Escalate to a moderator, Nyay Guide (Sahayak), or verified lawyer — with context intact.",
    example: "Connect · Nyay Guide or lawyer",
  },
  {
    step: "Track your formalised case",
    detail: "Follow status after you take the next step — review, filing, or ongoing help.",
    example: "Under Nyay Guide review",
  },
] as const;

export const HELP_AREAS: { title: string; desc: string; icon: LucideIcon }[] = [
  { title: "Cyber fraud & scams", desc: "UPI, phishing, fake customer care, online harassment", icon: Shield },
  { title: "Consumer complaints", desc: "Refunds, defective goods, e-commerce disputes", icon: Scale },
  { title: "Domestic violence & safety", desc: "Protection options, safety planning, next steps", icon: ShieldCheck },
  { title: "Tenancy & property", desc: "Eviction notices, deposits, ownership disputes", icon: Briefcase },
  { title: "Employment issues", desc: "Harassment, wrongful termination, unpaid dues", icon: Briefcase },
  { title: "Police & FIR guidance", desc: "Zero FIR, missing person, assault, follow-up", icon: FileText },
  { title: "Cheque bounce", desc: "Section 138 notices and practical next steps", icon: FileText },
  { title: "Motor accidents (MACT)", desc: "Compensation pathways after road accidents", icon: FileText },
  { title: "RTI & documentation", desc: "RTI drafts, notices, affidavits, complaint templates", icon: BookOpen },
  { title: "Family & maintenance", desc: "Custody, maintenance, and matrimonial questions", icon: Users },
];

export const AI_SPECIALISTS = [
  { name: "Cyber", desc: "Online fraud, UPI, phishing" },
  { name: "Civil", desc: "Property, tenant, contracts, consumer" },
  { name: "Criminal", desc: "FIR, theft, assault, missing person" },
  { name: "Domestic", desc: "Family abuse and safety pathways" },
  { name: "Scam", desc: "Pre-loss risk and scam patterns" },
  { name: "Documents", desc: "Notices, contracts, evidence review" },
] as const;

export const HUMAN_LADDER = [
  {
    title: "AI guidance first",
    detail: "Understand options and organise your situation without losing the thread.",
  },
  {
    title: "Moderator review",
    detail: "Sensitive or escalated matters can be reviewed by trained moderators when needed for safety.",
  },
  {
    title: "Nyay Guide / Sahayak",
    detail: "A human guide who can help you take practical next steps — with your case context carried forward.",
  },
  {
    title: "Verified lawyer",
    detail: "When you need counsel, connect with verified legal professionals who see what you’ve already prepared.",
  },
] as const;

export const CONTINUITY_ITEMS = [
  {
    title: "Complaint drafting",
    desc: "Step-by-step help for FIRs, consumer forums, notices, and more — always yours to review.",
  },
  {
    title: "Templates library",
    desc: "Rent agreements, RTI, affidavits, police complaints, and other everyday documents.",
  },
  {
    title: "Evidence upload",
    desc: "Attach screenshots, PDFs, and records so nothing important gets lost in chat history.",
  },
  {
    title: "Case reports & tracking",
    desc: "Structured summaries and formalised case status — so handoffs don’t start from zero.",
  },
] as const;

export const HELPLINES = [
  { number: "112", label: "Emergency", note: "Police, fire, ambulance" },
  { number: "181", label: "Women’s helpline", note: "Support and safety guidance" },
  { number: "1930", label: "Cyber fraud", note: "Also cybercrime.gov.in" },
  { number: "15100", label: "NALSA", note: "Free legal aid enquiry" },
] as const;

export const COMPARISON_ROWS = [
  {
    capability: "India procedure grounding",
    blogs: "Weak",
    genericAi: "Unreliable",
    directory: "N/A",
    nyaysahayak: "Yes — agents + legal corpus",
  },
  {
    capability: "Case continuity",
    blogs: "No",
    genericAi: "Weak",
    directory: "No",
    nyaysahayak: "Sessions + formalised cases",
  },
  {
    capability: "Human handoff",
    blogs: "No",
    genericAi: "No",
    directory: "Profiles only",
    nyaysahayak: "Moderator → Guide → Lawyer",
  },
  {
    capability: "Drafts & evidence",
    blogs: "Rare",
    genericAi: "Generic",
    directory: "No",
    nyaysahayak: "Templates + uploads + reports",
  },
] as const;

export const FAQ_ITEMS = [
  {
    q: "Is NyaySahayak a substitute for a lawyer?",
    a: "No. We help you understand options, organise your situation, and prepare documents. When you need representation, we connect you to verified legal professionals. We are not a law firm and do not guarantee legal outcomes.",
  },
  {
    q: "Is my information private?",
    a: "We treat sensitive matters carefully. Conversations are stored so your case can continue across sessions. Escalated cases may be reviewed by trained moderators only when needed for your safety. Read our Privacy Policy for details.",
  },
  {
    q: "What happens in an emergency?",
    a: "If you or someone else is in immediate danger, contact emergency services first — dial 112. NyaySahayak can guide you toward helplines like 181, 1930, and NALSA 15100, but it is a companion, not a replacement for emergency response.",
  },
  {
    q: "Does it work for any legal issue in India?",
    a: "We focus on everyday citizen issues — cyber fraud, consumer, domestic safety, property, employment, police/FIR pathways, documentation, and more. Complex litigation still needs a specialist lawyer.",
  },
  {
    q: "What is a Nyay Guide / Sahayak?",
    a: "A Nyay Guide (also called Sahayak) is a human helper in our handoff ladder. When AI guidance isn’t enough, they can review your situation and help you take practical next steps — without making you restart your story.",
  },
  {
    q: "How are lawyers verified?",
    a: "Lawyers on the platform carry a verified flag in our directory after our onboarding checks. Always confirm credentials independently for high-stakes representation. We connect you with context; we don’t replace your judgment.",
  },
  {
    q: "Can I use voice instead of typing?",
    a: "Yes. Describe your situation by voice in the case workspace. We designed this for people who are stressed or on mobile.",
  },
  {
    q: "Which languages are supported today?",
    a: "English is fully supported in the product UI. Hindi and Bengali coverage is expanding in parts of the experience, and guidance may appear in more languages depending on your path. We will not claim full product translation until it is complete.",
  },
  {
    q: "What is Clash Mode?",
    a: "Clash lets you practice courtroom-style arguments or frame a real-life case from both sides — prosecution and defence — so you understand the issues better. It is an educational tool, not legal advice or a court ruling.",
  },
  {
    q: "How much does it cost?",
    a: "Getting started and initial guidance is free. Formal case services or lawyer connections may have separate terms — we will always explain before you commit.",
  },
] as const;

export const FOOTER_LINKS = {
  product: [
    { label: "How it works", href: "#how-it-works" },
    { label: "Explore tools", href: "#explore" },
    { label: "Human help", href: "#human-help" },
    { label: "FAQ", href: "#faq" },
  ],
  resources: [
    { label: "About", href: "/about" },
    { label: "Scam heatmap", href: "/scam-heatmap" },
    { label: "Find a lawyer", href: "/find-help" },
    { label: "Search articles", href: "/search" },
    { label: "Legal library", href: "/legal-rights" },
    { label: "Helplines", href: "#helplines" },
  ],
  legal: [
    { label: "Privacy Policy", href: "/privacy" },
    { label: "Terms of Use", href: "/terms" },
    { label: "Disclaimer", href: "/terms#disclaimer" },
  ],
} as const;
