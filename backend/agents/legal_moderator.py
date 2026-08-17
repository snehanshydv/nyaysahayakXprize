from langchain_core.messages import SystemMessage
from langgraph.graph import END
import backend.database.supabase_db as supabase_db
from backend import case_dispatcher


def _resolve_location(state) -> dict:
    user_details = state.get("user_details") or {}
    structured_report = state.get("structured_report") or {}
    location = state.get("location") or {}
    if not isinstance(location, dict) or not location:
        location = user_details.get("location") or {}
    if (not isinstance(location, dict) or not location) and isinstance(structured_report, dict):
        nested = structured_report.get("location")
        if isinstance(nested, dict):
            location = nested
    return location if isinstance(location, dict) else {}


def legal_moderator_agent(state):
    print(f"\n⚖️ LEGAL MODERATOR AGENT ACTIVATED")

    structured_report = state.get("structured_report", {})
    user_details = state.get("user_details", {})
    user_id = user_details.get("user_id", "anonymous")
    session_id = user_details.get("session_id")
    case_id = state.get("case_id")
    user_statement = state.get("user_statement", "")
    location = _resolve_location(state)
    pdf_url = state.get("pdf_url") or (
        structured_report.get("pdf_url") if isinstance(structured_report, dict) else None
    )

    # Second pass: apply moderator resolution from admin/chat resume answers
    if state.get("waiting_for_moderator_resolution"):
        print("   → Applying moderator resolution from resume input")
        answers = state.get("collected_answers") or {}
        if not isinstance(answers, dict):
            answers = {}

        # Prefer explicit keys from admin resume; fall back to last human message
        moderator_response = str(
            answers.get("moderator_response")
            or answers.get("pending_question")
            or ""
        ).strip()
        if not moderator_response:
            for msg in reversed(state.get("messages") or []):
                if hasattr(msg, "type") and msg.type == "human":
                    moderator_response = str(msg.content or "").strip()
                    break

        options_raw = answers.get("moderator_options") or answers.get("options") or ""
        options: list = []
        if isinstance(options_raw, list):
            options = options_raw
        elif isinstance(options_raw, str) and options_raw.strip():
            # Comma / newline separated labels
            for part in options_raw.replace("\n", ",").split(","):
                label = part.strip()
                if label:
                    options.append({"label": label, "payload": label})

        if not moderator_response:
            moderator_response = (
                "Based on my review, here are the immediate next steps you should take."
            )

        # Criminal / high-severity cases: ensure lawyer + Nyay Guide (sahayak) options at flow end.
        incident = str((structured_report or {}).get("incident_type") or "").lower()
        category = str(state.get("case_category") or "").lower()
        is_criminalish = category == "criminal" or any(
            k in incident for k in ("criminal", "missing", "kidnap", "assault", "theft", "robbery")
        )
        if is_criminalish and not options:
            options = [
                {"label": "Recommend a lawyer", "node": "lawyer_forwarder", "payload": "Please recommend a lawyer for my case"},
                {"label": "Connect to Nyay Guide", "node": "sahayak", "payload": "Request Human Help"},
            ]

        try:
            if case_id:
                supabase_db.resolve_intervention_case(
                    case_id,
                    moderator_response,
                    options,
                    routing_recommendation=state.get("routing_recommendation"),
                )
                print(f"   ✅ Intervention {case_id} resolved via moderator input")
                case_dispatcher.notify_intervention_claimed(case_id, "", None)
        except Exception as e:
            print(f"   ❌ Failed to resolve intervention: {e}")

        response_text = (
            "✅ **MODERATOR RESOLUTION SUBMITTED**\n\n"
            f"{moderator_response}\n\n"
            "_The user will receive these next steps and options._"
        )
        return {
            "messages": [SystemMessage(content=response_text)],
            "final_response": response_text,
            "intervention_required": True,
            "intervention_collection": "moderator",
            "case_id": case_id,
            "suggested_actions": options if isinstance(options, list) else [],
            "waiting_for_moderator_resolution": False,
            "awaiting_user_input": False,
            "input_prompts": [],
            "location": location,
            "next_step": END,
        }

    # First pass: enqueue case and push-notify ranked online moderators
    print("   Reviewing case and creating intervention...")
    intervention_case_id = case_id or "Unknown"
    try:
        intervention_case_id = supabase_db.create_intervention_case(
            user_id,
            structured_report,
            collection_name="moderator",
            session_id=session_id,
            user_statement=user_statement,
            location=location,
            case_id=case_id,
            pdf_url=pdf_url,
        )
        print(f"   ✅ Case written to queue 'moderator' with ID: {intervention_case_id}")
        if intervention_case_id:
            agent_payload = {
                "source": "legal_moderator_agent",
                "user_id": user_id,
                "session_id": session_id,
                "user_statement": user_statement,
                "location": location,
                "pdf_url": pdf_url,
                "case_category": state.get("case_category"),
                "user_details": {
                    k: user_details.get(k)
                    for k in ("user_id", "session_id", "user_name", "name")
                    if user_details.get(k) is not None
                },
                "waiting_for_moderator_resolution": True,
            }
            recipients = case_dispatcher.dispatch_intervention(
                case_id=intervention_case_id,
                user_id=user_id,
                structured_report=structured_report if isinstance(structured_report, dict) else {},
                collection_name="moderator",
                session_id=session_id,
                user_statement=user_statement,
                location=location,
                agent_payload=agent_payload,
            )
            print(f"   Notified moderators: {recipients}")
    except Exception as e:
        print(f"   ❌ Failed to write/dispatch intervention: {e}")

    response_text = (
        "🚨 **MODERATOR REVIEW INITIATED**\n\n"
        "Your case needs a human legal moderator review due to risk and complexity signals "
        "detected in the report.\n\n"
        "_Awaiting moderator response and recommended options (same fields as the moderator dashboard)._"
    )

    input_prompts = [
        {
            "id": "moderator_response",
            "label": "Moderator response to the user",
            "hint": "Same as Legal Moderator Dashboard — guidance text the user will see.",
            "node_id": "legal_moderator",
            "kind": "moderator_response",
        },
        {
            "id": "moderator_options",
            "label": "Suggested action options (comma-separated labels)",
            "hint": "Optional. Example: File FIR, Contact cyber cell, Consult lawyer",
            "node_id": "legal_moderator",
            "kind": "moderator_options",
        },
    ]

    return {
        "messages": [SystemMessage(content=response_text)],
        "final_response": response_text,
        "intervention_required": True,
        "intervention_collection": "moderator",
        "case_id": intervention_case_id,
        "suggested_actions": [],
        "waiting_for_moderator_resolution": True,
        "awaiting_user_input": True,
        "input_prompts": input_prompts,
        "pending_question": "Enter moderator resolution for this case",
        "location": location,
        "next_step": END,
    }
