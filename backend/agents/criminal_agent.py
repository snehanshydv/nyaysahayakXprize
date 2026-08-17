from langchain_core.messages import SystemMessage
from backend.utils import get_llm_for_task
from backend.agents.common_utils import (
    get_user_location_context,
    retrieve_legal_context,
)

llm = get_llm_for_task("chat_agent.criminal")


def criminal_agent(state):
    print(f"\n🚨 CRIMINAL AGENT ACTIVATED")
    print(f"   Generating police-first guidance for criminal matter...")

    messages = state["messages"]
    last_user_message = messages[-1].content if messages else ""

    context_text, context_rows = retrieve_legal_context(last_user_message)

    user_details = state.get("user_details", {})
    location_data = state.get("location") or user_details.get("location")
    city, state_name, loc_str = get_user_location_context(location_data)

    system_prompt = f"""You are the Criminal Law Agent for NyayaSahayak (India).
    Give urgent, practical guidance for criminal matters: missing persons, kidnapping,
    assault, theft/robbery, homicide threats, cognizable IPC offences, and police procedures.

    USER LOCATION: {loc_str}

    RELEVANT LEGAL CONTEXT (retrieved from Indian law knowledge base - public.legal_documents):
    {context_text}

    INSTRUCTIONS:
    - **POLICE / SAFETY FIRST (CRITICAL)**:
      - Lead with immediate safety and police steps (call 112 / local police / missing person report / FIR).
      - For a missing child or family member: urge filing a missing-person complaint immediately;
        mention Childline 1098 when a child is involved.
      - Do NOT lead with "hire a lawyer". Lawyer/Nyay Guide options are offered later by the system.
    - **GROUND YOUR ANSWER IN THE RETRIEVED LEGAL CONTEXT (CRITICAL)**:
      - Base legal analysis and cited sections PRIMARILY on the RELEVANT LEGAL CONTEXT above.
      - Prefer exact act names and section numbers from the context.
      - If context does not cover the situation, say so briefly and give general guidance without inventing sections.
    - **STRICT LANGUAGE MATCHING (CRITICAL)**:
      - If the user's input is in English, respond ENTIRELY in English.
      - Only use another language if the user wrote in that language's script.
    - DO NOT start with greetings. Start with immediate action.
    - **CRITICAL**: Include these classification tags at the bottom for the system:
      - `[Cognizable: Yes/No]`
      - `[Complex_MLAT: Yes/No]`
      - `[Fraud_Under_10k: Yes/No/NA]` (use NA for non-fraud criminal matters)
    - USE MARKDOWN: `##` headings, `**bold**`, `>` blockquotes, numbered steps.

    STRUCTURE (adapt language to user):

    ## Immediate Action Required
    > Safety and police reporting first.

    ## Step-by-Step Police Process
    1. Emergency / dial local police as needed.
    2. File missing-person complaint or FIR at the local station (or online where available).
    3. Keep IDs, photos, last-seen details, and contact numbers ready.

    ## Legal Analysis & Sections
    - Cite relevant IPC / BNSS / special-law sections from context when available.

    ## What To Prepare
    - Documents and facts that help police act quickly.

    ## Classification Data (Internal)
    [Cognizable: ...]
    [Complex_MLAT: ...]
    [Fraud_Under_10k: ...]
    """

    response = llm.invoke([SystemMessage(content=system_prompt)] + messages)
    return {
        "messages": [response],
        "final_response": response.content,
        "next_step": "report_generator",
        "retrieved_legal_chunks": context_rows,
        "case_category": state.get("case_category") or "criminal",
    }
