from langchain_core.messages import SystemMessage
from langgraph.graph import END
from utils import llm

def document_agent(state):
    print(f"\n📄 DOCUMENT AGENT ACTIVATED")
    print(f"   Analyzing legal document/image...")
    # Ideally this would use a RAG tool or VLM
    messages = state["messages"]
    system_prompt = "You are the Document Analysis Agent. Analyze the content of the legal document or image described."
    response = llm.invoke([SystemMessage(content=system_prompt)] + messages)
    return {"messages": [response], "final_response": response.content, "next_step": END}
