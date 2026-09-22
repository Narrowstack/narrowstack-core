# Build vs buy — recommendation (chat with modeled data)

**As of:** 2026-09-22  
**Full scorecard:** [`build-vs-buy-chat-with-modeled-data.md`](./build-vs-buy-chat-with-modeled-data.md)

## Verdict

**Hybrid.** Self-host a thin chat shell (**LibreChat** default; **Open WebUI** alternate after license diligence). **Build** Core MCP/OpenAPI tools so metrics, marts, and ACL stay in Core. **Adopt** LangGraph (or Haystack/LlamaIndex) for the headless walking skeleton. Add **Onyx** / **RAGFlow** only as doc adjuncts. **Hermes** = pattern + optional operator sidecar. **Do not buy SaaS** for v1; **avoid** Dify default, AnythingLLM backbone, AgentSwarms, and vector RAG as MetricFlow substitute.

## Why (swing criteria)

1. Integration / Core source of truth  
2. Single metric ACL plane  
3. One-VM hosting overhead  

Chat UI is commodity; governed answers are the product.

## Walking skeleton

Core tools → LangGraph headless proof (PRD step 6) → LibreChat on MCP → doc sidecars only if sold.

## Confidence / reopen

**High** on hybrid shape; **med** on LibreChat vs OWUI and Onyx timing.  
**Reopen:** OWUI license blocks packaging; buyer needs SCIM beyond LibreChat; org-doc SKU sold; VM RAM clash; MCP identity fails review; or **2027-03-01**.

_Not operator-decided until Tucker stamps it._
