from langchain_core.messages import SystemMessage
from langgraph.graph import END
from backend.utils import get_llm_for_task

llm = get_llm_for_task("chat_agent.scam")

from geopy.geocoders import Nominatim
from backend.database.vector_db import VectorDB
from backend.database import supabase_db
from backend.agents.common_utils import (
    get_user_location_context,
    get_local_scam_summary,
    retrieve_legal_context,
)
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

    # 2B. Retrieve Similar Scam Trends from Supabase vectorized mock_scams
    similar_trends = supabase_db.find_similar_mock_scam_trends(
        query_text=last_message,
        city=city,
        limit=5,
        similarity_threshold=0.78,
    )

    similar_trend_context = "No highly similar local scam trend found from user reports."
    if similar_trends:
        lines = []
        for trend in similar_trends:
            title = trend.get("title") or trend.get("scam_type") or "Scam alert"
            t_city = trend.get("city") or city
            similarity = trend.get("similarity", 0)
            lines.append(f"- {title} ({t_city}) [similarity={similarity}]")
        similar_trend_context = "\n".join(lines)

    # 3. Retrieve relevant Indian law context via the RAG pipeline (public.legal_documents)
    context_text, context_rows = retrieve_legal_context(last_message)

    # 4. Store New Scam Report - MOVED TO REPORT_AGENT
    # To ensure high-quality scam vectors in Postgres, we now wait for report_agent.py 
    # to generate the structured summary and store that instead of the raw user query.

    # 5. System Prompt with Geo-Context
    system_prompt = f"""You are the Scam Analysis Agent. 
    Analyze the scam trend, assess risk, and guide the user on immediate protective measures.
    
    USER LOCATION: {loc_str}
    
    LOCAL SCAM TRENDS IN {city}:
    {local_scam_context}

    SEMANTICALLY SIMILAR USER-REPORTED SCAM TRENDS (mock_scams):
    {similar_trend_context}

    RELEVANT LEGAL CONTEXT (retrieved from Indian law knowledge base - public.legal_documents):
    {context_text}
    
    INSTRUCTIONS:
    - If the user is reporting a scam, acknowledge that it has been noted for the {city} area.
    - If 'LOCAL SCAM TRENDS' contains relevant info, Warn the user about it!
    - If 'SEMANTICALLY SIMILAR USER-REPORTED SCAM TRENDS' has entries, explicitly alert the user that a similar trend exists in/near their location and ask them to stay cautious.
    - detailed specific advice based on the type of scam.
    - **GROUND YOUR LEGAL ANALYSIS IN THE RETRIEVED LEGAL CONTEXT**: When citing applicable laws/sections (e.g. IT Act, IPC/BNS, Consumer Protection Act), prefer the exact act names and section numbers present in the RELEVANT LEGAL CONTEXT above; do not invent section numbers.
    - If no location is detected, advise the user to enable location for better alerts.
    - **STRICT LANGUAGE MATCHING (CRITICAL)**: 
      - If the user's input is in English, you MUST respond ENTIRELY in English.
      - Do NOT let the USER LOCATION or LOCAL SCAM TRENDS influence your response language. (e.g., if the user asks in English but the location is West Bengal, RESPOND IN ENGLISH).
      - ONLY respond in another language (like Bengali or Hindi) if the user's input is EXPLICITLY written in that language's script.
    """
    
    response = llm.invoke([SystemMessage(content=system_prompt)] + messages)
    return {
        "messages": [response],
        "final_response": response.content,
        "next_step": END,
        "structured_report": {"incident_type": "Scam/Fraud", "risk_level": "Medium"},
        "retrieved_legal_chunks": context_rows,
        "matched_scam_trends": similar_trends or [],
    }
