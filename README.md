# Customer Support AI Agent (Amazon Bedrock AgentCore)

A production-style customer support agent built on **Amazon Bedrock AgentCore** and the
**Strands Agents SDK**. The agent answers customer questions and can track orders, process
refunds, search a product knowledge base, calculate loyalty discounts, browse the web, and
remember customers across sessions.

The full agent implementation lives in [`main.py`](main.py).

---

## What the agent can do

| Capability | How it works | Tool / Feature |
|------------|--------------|----------------|
| **Order tracking** | Looks up orders through the AgentCore Gateway (API Gateway → Lambda) | `order-tracker` gateway tools |
| **Refund processing** | Initiates refunds and return labels through the Gateway (Lambda) | `refund-processor` gateway tools |
| **Knowledge base search (RAG)** | Retrieves answers from a product catalog knowledge base | `search_knowledge_base` |
| **Loyalty discount calculation** | Runs exact business-rule math in a sandbox | `calculate_loyalty_discount` (Code Interpreter) |
| **Long-term memory** | Remembers customer facts and preferences across sessions | `MemoryHook` + AgentCore Memory |
| **Web browsing** | Fetches a live web page and returns its title/content | `browse_web` (HTTP) / `AgentCoreBrowser` |

---

## Architecture

```
Customer message
      │
      ▼
┌──────────────────────────────┐
│  @app.entrypoint  invoke()   │   AgentCore Runtime (async handler)
│                              │
│  1. MemoryHook: retrieve     │──► AgentCore Memory (facts + preferences)
│     customer context         │
│                              │
│  2. Agent picks a tool:      │
│     ├─ Gateway tools ────────│──► AgentCore Gateway ──► API Gateway / Lambda
│     ├─ search_knowledge_base │──► Bedrock Knowledge Base (RAG)
│     ├─ calculate_loyalty_... │──► Code Interpreter (sandboxed Python)
│     └─ browse_web            │──► live web page
│                              │
│  3. Bedrock model (Nova)     │   composes the final answer
│                              │
│  4. MemoryHook: save turn    │──► AgentCore Memory
└──────────────────────────────┘
      │
      ▼
Response to customer
```

The Bedrock model decides **which tool to call** based on each tool's docstring; the code
just makes the tools available and wires up memory, gateway, and the runtime entrypoint.

---

## Project structure

```
customersupportagent/
├── main.py                 # The agent — all 8 implementation sections
├── product_catalog.txt     # Knowledge base source (uploaded to S3)
├── REFLECTION.md           # Engineering reflection (design, challenges, production)
├── fix_memory.sh           # IAM helper: grant memory permissions to the agent role
├── fix_kb.sh               # IAM helper: grant knowledge-base Retrieve permission
├── test_gateway.py         # Standalone script to test the Gateway connection
├── agentcore/              # AgentCore project config + CDK infrastructure
└── screenshots/            # Functional test evidence (Tests 1–6)
```

---

## Key implementation notes (`main.py`)

1. **App init** — one `BedrockAgentCoreApp()` at module level.
2. **Config** — `GATEWAY_URL`, `KB_ID`, `REGION`, `MEMORY_ID`.
3. **Model + clients** — `BedrockModel` (Nova), `MemoryClient`, `bedrock-agent-runtime`.
4. **Namespace helper** — `get_namespaces()` reads memory strategies at runtime.
5. **Memory hook** — `retrieve_customer_context` (before) and `save_support_interaction` (after).
6. **Knowledge base tool** — `search_knowledge_base()` calls the Bedrock Retrieve API.
7. **Loyalty tool** — `calculate_loyalty_discount()` runs code in the Code Interpreter, with a
   tier-only fallback if the interpreter is unavailable. Returns `points_redeemed`,
   `tier_discount_pct`, `final_total`, `remaining_points`.
8. **Entrypoint** — `async def invoke(payload, context=None)` connects to the Gateway, builds
   the tool list, runs the agent, and surfaces gateway errors clearly instead of crashing.

---

## Running it

Prerequisites: Python 3.13+, `uv`, AWS CLI v2, and the AgentCore starter toolkit. AWS
resources (Gateway, Knowledge Base, Memory, Lambdas) must be created first, and their IDs set
in `main.py`.

```bash
# Install dependencies
uv sync

# Deploy to AgentCore Runtime
agentcore deploy

# Invoke the deployed agent
agentcore invoke '{"prompt": "Can you track order ORD-001?", "customer_id": "CUST-123", "session_id": "s1"}'

# View logs
agentcore logs --since 5m
```

The agent execution role also needs permissions for `bedrock-agentcore` memory actions and
`bedrock:Retrieve` (see `fix_memory.sh` and `fix_kb.sh`).

---

## Functional tests

All six scenarios are verified in the `screenshots/` folder:

1. **Order tracking** — returns shipping status, tracking number, carrier
2. **Refund processing** — returns refund ID, APPROVED status, credit timeline
3. **Knowledge base (RAG)** — returns Platinum tier benefits from the catalog
4. **Long-term memory** — recalls the customer's name and preference in a new session
5. **Loyalty discount** — returns tier discount %, points redeemed, final total, remaining points
6. **Web browsing** — returns the live page title from a website

---

## Notable engineering challenges (see `REFLECTION.md`)

- Fixed a managed-browser API mismatch (`region=` vs `region_name=`).
- Pinned `mcp<2` to resolve a Gateway protocol validation error.
- Added scoped IAM policies for Memory and Knowledge Base access.
- Handled API Gateway throttling and surfaced gateway errors clearly.
- Worked around a Playwright/anyio runtime crash with an HTTP-based browsing tool.

Built as part of a hands-on Amazon Bedrock AgentCore project.
