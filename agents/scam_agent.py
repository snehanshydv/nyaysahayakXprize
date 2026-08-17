from langchain_core.messages import SystemMessage
from langgraph.graph import END
from utils import llm

from geopy.geocoders import Nominatim
from database.vector_db import VectorDB
from agents.common_utils import get_user_location_context, get_local_scam_summary
import threading

# Initialize VectorDB
vector_db = VectorDB()

def scam_agent(state):
    print(f"\n🚫 SCAM AGENT ACTIVATED")
    print(f"   Analyzing scam trend and risk...")
    
    messages = state["messages"]
    user_details = state.get("user_details", {})
    location_data = user_details.get("location")
    last_message = messages[-1].content if messages else ""
    
    # 1. Geolocation Logic
    city, state_name, loc_str = get_user_location_context(location_data)

    # 2. Retrieve Local Scam Trends
    local_scam_context = get_local_scam_summary(city)

    # 3. Store New Scam Report (Simple Heuristic for now)
    # If the user says "report", "received", "happened", etc. and it's long enough
    is_report = any(keyword in last_message.lower() for keyword in ["report", "scam happened", "i received", "got a call", "message asking"])
    if is_report and len(last_message) > 20 and city != "Unknown" and city != "India":
        # Run storage in background to avoid blocking
        def store_scam():
            vector_db.add_scam(last_message, {"city": city, "state": state_name, "source": "user_report"})
            
        threading.Thread(target=store_scam).start()
        print("   📝 Detecting new scam report - storing in background.")

    # 4. System Prompt with Geo-Context
    system_prompt = f"""You are the Scam Analysis Agent. 
    Analyze the scam trend, assess risk, and guide the user on immediate protective measures.
    
    USER LOCATION: {loc_str}
    
    LOCAL SCAM TRENDS IN {city}:
    {local_scam_context}
    
    INSTRUCTIONS:
    - If the user is reporting a scam, acknowledge that it has been noted for the {city} area.
    - If 'LOCAL SCAM TRENDS' contains relevant info, Warn the user about it!
    - detailed specific advice based on the type of scam.
    - If no location is detected, advise the user to enable location for better alerts.
    """
    
    response = llm.invoke([SystemMessage(content=system_prompt)] + messages)
    return {"messages": [response], "final_response": response.content, "next_step": END, "structured_report": {"incident_type": "Scam/Fraud", "risk_level": "Medium"}}
