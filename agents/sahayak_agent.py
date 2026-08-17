from langchain_core.messages import SystemMessage
from langgraph.graph import END

def sahayak_agent(state):
    print(f"\n🤝 SAHAYAK AGENT (HUMAN HANDOFF) ACTIVATED")
    print(f"   Routing to human expert...")
    
    # Check if this was a direct handoff request or feedback
    # For now, we assume any entry here is a request for help
    
    response_text = "I have forwarded your request to a Physical Sahayak. They will contact you shortly to assist with filing the complaint."
    
    return {
        "messages": [SystemMessage(content=response_text)], 
        "final_response": response_text, 
        "suggested_actions": [], # Clear actions on end
        "next_step": END
    }
