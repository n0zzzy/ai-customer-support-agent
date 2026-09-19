# Engineering Reflection: Production-Grade Customer Support AI Agent

## Design Decision: Namespace-Driven Long-Term Memory

A key decision was implementing the `MemoryHook` class with a dynamic namespace
helper (`get_namespaces`). Rather than hardcoding memory paths, the agent fetches
its configured memory strategies from Amazon Bedrock AgentCore Memory at runtime and
targets the correct namespaces automatically — semantic facts
(`cs_agent/{actorId}/facts`) and user preferences
(`cs_agent/{actorId}/preferences`). Two lifecycle callbacks drive it:
`retrieve_customer_context` enriches each incoming user message with relevant
memories, and `save_support_interaction` persists the completed turn after the agent
responds. This decouples state management from the core agent loop and scales
cleanly as new strategies are added. It was validated end to end: after introducing
"Jane" and her "concise responses" preference in one session, the agent recalled
both in a brand-new session — confirming genuine cross-session persistence rather
than in-context recall.

## Challenge: Log-Driven Runtime Debugging

The hardest part was making all eight components run together reliably in the
deployed runtime. Most failures surfaced only after deployment and were diagnosed
through CloudWatch stack traces. First, the managed browser raised a `TypeError`
because the installed tools library expects `region=` rather than `region_name=`.
Next, gateway tool calls (order tracking and refunds) failed with a Pydantic
`resultType` validation error, traced to an incompatible `mcp 2.x` resolution;
pinning the dependency to `mcp>=1.27,<2` (1.30.0) restored gateway compatibility.
The execution role was also missing `bedrock-agentcore` memory actions
(`GetMemory`, `CreateEvent`) and the `bedrock:Retrieve` action, which caused silent
`AccessDeniedException` failures in memory and RAG until scoped inline IAM policies
were attached. Finally, rapid repeated calls to the same gateway tool occasionally
triggered API Gateway `403` throttling, mitigated by tightening the system prompt
against redundant retries and handling tool failures gracefully so the agent still
answers with the information it already holds.

A separate, deeper issue was the Playwright-based `AgentCoreBrowser` crashing the
runtime with `cannot create weak reference to 'NoneType'` — a library-level
event-loop incompatibility that persisted across lazy loading, `nest_asyncio`, and
both sync and async entrypoints. The implementation is retained for reference, and a
lightweight HTTP-based `browse_web` tool provides reliable live browsing, verified
against amazon.com. The recurring lesson was disciplined isolation: reproduce the
failure, read the exact trace, and determine whether the fault lies in the code, the
dependency graph, or the AWS resource configuration.

## Production Consideration: Observability and Guardrails

For production I would add Cedar-based guardrails to constrain sensitive actions such
as refunds, structured CloudWatch tracing to monitor multi-tool execution paths and
per-tool success rates (valuable given the throttling observed in testing), and
metric filters with alarms on error and tool-failure rates for proactive incident
response and high availability.
