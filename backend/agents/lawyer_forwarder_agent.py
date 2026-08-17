from langchain_core.messages import SystemMessage
from langgraph.graph import END
import backend.database.supabase_db as supabase_db
import json

def lawyer_forwarder_agent(state):
    print("\n⚖️ LAWYER RECOMMENDATION AGENT ACTIVATED")
    
    # 1. Look for structured report or raw query to determine category
    structured_report = state.get("structured_report", {})
    incident_type = structured_report.get("incident_type", "")
    user_id = state.get("user_id", "")
    user_name = state.get("user_name", "User")
    session_id = state.get("session_id", "")
    
    # Fallback if no report exists (e.g. direct flow jump)
    if not incident_type:
        messages = state.get("messages", [])
        if messages:
            last_msg = messages[-1].content.lower()
            if "cyber" in last_msg or "fraud" in last_msg or "scam" in last_msg:
                incident_type = "Cyber Crime"
            elif "property" in last_msg or "civil" in last_msg:
                incident_type = "Civil Law"
            elif "divorce" in last_msg or "family" in last_msg or "domestic" in last_msg:
                incident_type = "Family Law"
            else:
                incident_type = "General"
    
    print(f"   Searching for lawyers specializing in: {incident_type}")
    
    # 2. Fetch lawyers from database
    lawyers = supabase_db.search_lawyers_by_specialization(incident_type, limit=5)
    
    # 3. Forward this case to the lawyer_cases table so lawyers can see it
    lawyer_case_id = None
    pdf_url = state.get("pdf_url") or (
        structured_report.get("pdf_url") if isinstance(structured_report, dict) else None
    )
    if not pdf_url and state.get("case_id"):
        try:
            pdf_url = supabase_db.get_case_pdf_url(state.get("case_id"))
        except Exception:
            pdf_url = None
    if user_id and structured_report:
        try:
            lawyer_case_id = supabase_db.forward_case_to_lawyer(
                user_id=user_id,
                user_name=user_name,
                structured_report=structured_report,
                session_id=session_id or None,
                pdf_url=pdf_url,
            )
            print(f"   ✅ Case forwarded to lawyer dashboard with ID: {lawyer_case_id}")
        except Exception as e:
            print(f"   ⚠️ Could not forward case to lawyer dashboard: {e}")
    
    # 4. Format the response using Markdown
    if lawyers and len(lawyers) > 0:
        response_text = f"✅ I've found **{len(lawyers)} verified lawyers** specializing in **{incident_type}** who can help with your case:\n\n"
        
        for idx, lawyer in enumerate(lawyers, 1):
            name = lawyer.get("name", "Verified Lawyer")
            spec = lawyer.get("specialization", "General Practice")
            exp = lawyer.get("experience", 0)
            rate = lawyer.get("hourly_rate", "Contact for pricing")
            rating = lawyer.get("rating", 5.0)
            bio = lawyer.get("bio", "Experienced legal professional.")
            loc = lawyer.get("location", "India")
            
            response_text += f"### {idx}. {name}\n"
            response_text += f"**Specialty:** {spec} | **Experience:** {exp} Years\n"
            response_text += f"**Rating:** {rating} ⭐ | **Location:** {loc}\n"
            response_text += f"> \"{bio}\"\n\n"
            
        response_text += "---\n*Click on any lawyer below to view their full profile and connect with them.*"
        
        # Return structured lawyer data for frontend rendering
        actions = [
            {"label": "View Lawyer Profiles", "action": "show_lawyers", "payload": "show_lawyers"},
            {"label": "No, I'll handle it myself", "action": "end", "payload": "No thanks, I'll proceed on my own."}
        ]
        
    else:
        # Fallback if the database is empty or queries fail
        response_text = f"We are currently updating our database of verified lawyers for **{incident_type}**.\n\nIn the meantime, you can visit the [National Legal Services Authority (NALSA)](https://nalsa.gov.in/) website to find free legal aid in your jurisdiction."
        lawyers = []
        actions = []
        
    return {
        "messages": [SystemMessage(content=response_text)],
        "final_response": response_text,
        "next_step": END,
        "suggested_actions": actions,
        "recommended_lawyers": lawyers,        # Structured lawyer data for frontend
        "lawyer_case_id": lawyer_case_id,       # The created lawyer case ID
        "show_lawyer_panel": True if lawyers else False  # Signal to frontend
    }
