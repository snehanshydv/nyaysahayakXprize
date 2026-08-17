from langchain_core.messages import SystemMessage
from langgraph.graph import END
from websocket_manager import manager
import sys
import os

# Ensure the parent directory is in sys.path so we can import websocket_manager
parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if parent_dir not in sys.path:
    sys.path.append(parent_dir)

def legal_moderator_agent(state):
    print(f"\n⚖️ LEGAL MODERATOR AGENT ACTIVATED")
    print(f"   Reviewing case for statutory compliance and risk...")
    
    # Extract report from state (populated by Cyber Agent)
    structured_report = state.get("structured_report", {})
    incident_type = structured_report.get("incident_type", "Unknown")
    risk_level = structured_report.get("risk_level", "Low")
    
    user_details = state.get("user_details", {})
    user_id = user_details.get("user_id", "Unknown")
    
    # Broadcast case to the frontend WebSocket directly
    payload = {
        "event": "new_case",
        "user_id": user_id,
        "incident_type": incident_type,
        "risk_level": risk_level,
        "structured_report": structured_report
    }
    
    try:
        manager.broadcast_sync(payload)
        print("   ✅ Case broadcasted to connected Legal Moderators via WebSockets.")
    except Exception as e:
        print(f"   ❌ Failed to broadcast case to WebSockets: {e}")
    
    # Send a confirmation response back to the user
    response_text = "🚨 **HIGH CRITICALITY CASE FLAGGED**\n\nYour case has been flagged as critically urgent due to the nature of the financial incident or international complexity.\n\n_We have successfully forwarded your case details in real-time to our human Legal Moderators on duty. They are currently reviewing the incident and will provide you with verified instructions shortly._"
    
    # Check if satisfied logic
    response_text += "\n\n***\n**While you wait, are you satisfied with this automated response?**\n*If not, you can ask for a lawyer suggestion or request to be assigned a Nyaysahayak (human).* "
    
    return {
        "messages": [SystemMessage(content=response_text)], 
        "final_response": response_text,
        "suggested_actions": [
            {"label": "Connect to Nyay Guide (Human)", "node": "sahayak", "payload": "I need human help"},
            {"label": "Download Report", "action": "download_pdf", "payload": "report_id_123"}
        ],
        "next_step": END
    }
