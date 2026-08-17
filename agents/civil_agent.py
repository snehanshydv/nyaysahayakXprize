from langchain_core.messages import SystemMessage
from langgraph.graph import END
from utils import llm

def civil_agent(state):
    print(f"\n⚖️ CIVIL AGENT ACTIVATED")
    print(f"   Generating legal advice for civil dispute...")
    messages = state["messages"]
    system_prompt = "You are the Civil/Juridical Agent. Suggest next steps, FIR procedures, relevant IPC sections, and recommend finding a lawyer if needed."
    response = llm.invoke([SystemMessage(content=system_prompt)] + messages)
    return {"messages": [response], "final_response": response.content, "next_step": END}
