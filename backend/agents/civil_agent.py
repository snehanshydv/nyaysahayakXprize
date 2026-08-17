from langchain_core.messages import SystemMessage
from langgraph.graph import END
from backend.utils import get_llm_for_task

llm = get_llm_for_task("chat_agent.civil")
from backend.agents.common_utils import retrieve_legal_context


def civil_agent(state):
    print(f"\n⚖️ CIVIL AGENT ACTIVATED")
    print(f"   Generating legal advice for civil dispute...")
    messages = state["messages"]
    last_user_message = messages[-1].content if messages else ""

    # Retrieve relevant Indian law context via the RAG pipeline (public.legal_documents)
    context_text, context_rows = retrieve_legal_context(last_user_message)

    system_prompt = f"""You are the Civil/Juridical Agent. Suggest next steps for civil matters
    (property, tenancy, consumer, contracts, family/divorce disputes that are not criminal).
    Cite relevant civil/family law provisions from context. Do not handle missing-person or
    police FIR criminal matters — those belong to the criminal agent.

    RELEVANT LEGAL CONTEXT (retrieved from Indian law knowledge base - public.legal_documents):
    {context_text}
    
    INSTRUCTIONS:
    - **GROUND YOUR ANSWER IN THE RETRIEVED LEGAL CONTEXT (CRITICAL)**:
      - Base your legal analysis and cited sections PRIMARILY on the RELEVANT LEGAL CONTEXT above.
      - When you state an act/section, prefer the exact act names and section numbers present in the context.
      - If the retrieved context does not cover the situation, say so briefly and give general guidance without inventing section numbers.
    - **STRICT LANGUAGE MATCHING (CRITICAL)**: 
      - If the user's input is in English, you MUST respond ENTIRELY in English.
      - ONLY respond in another language (like Bengali or Hindi) if the user's input is EXPLICITLY written in that language's script.
    """
    response = llm.invoke([SystemMessage(content=system_prompt)] + messages)
    return {
        "messages": [response],
        "final_response": response.content,
        "next_step": END,
        "retrieved_legal_chunks": context_rows,
    }
