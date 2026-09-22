🌐 last30days v1.0.0 · synced 2026-09-22

What I learned:

**The 30-day conversation is about which shell to put in front of models - not about reinventing the warehouse.** Roundup posts still crown Open WebUI as the default self-hosted ChatGPT clone (Pinggy, Aug 27: "most popular self-hosted AI chat… RAG, Pipelines, and SSO"), with LibreChat as the multi-provider + agents/MCP workbench and LobeChat as the multi-agent MCP workspace. That matches the deep-research sibling's "thin harness vs full platform" split: community heat tracks chat UX and provider flexibility, while enterprise connector/ACL depth shows up in vendor comparison pieces (Onyx, RAGFlow) more than in casual Reddit threads.

**Hermes Agent is the month's named peer for the personal/self-improving harness shape.** Nous Research's product site and HN coverage (around Sep 1) pitch persistent memory, self-created skills, and Telegram/Discord/Slack gateways - the same "kinda close" reference the operator flagged. GitHub project-mode still lights up coding agents (OpenHands ~89k stars) and workflow platforms (Dify ~157k) harder than chat UIs, but those are adjacent categories: OpenHands is AI-driven development, not chat-with-modeled-business-data. TikTok "best OSS repos" clips this window also pushed personal agent platforms (Nanobot: WebUI + channels + MCP + cron) - same Hermes-adjacent niche, not enterprise RAG.

**Local operators still split Open WebUI vs LibreChat on setup vs MCP.** In r/LocalLLaMA's OpenWebUI vs LibreChat thread, one commenter summarized the lived tradeoff: "I found OpenWebUI setup easier than librechat. Librechat have more native MCP setup. UX I find OpenWebUI more solid and clear." Another LibreChat user: "It was fairly easy to setup in docker. My biggest annoyance is that MCP must be configured via the YML file and can't be configured via the GUI." Document-first folks still peel off to AnythingLLM ("I prefer anythingllm, has a good UI and really nice rag support"). Signal quality > star counts: Reddit was rate-limited mid-run (17 threads then 429), X was skipped (stale cookies), YouTube returned nothing in-window - treat community volume as partial.

**License and "who owns the knowledge plane" are the live procurement fights.** First-party positioning this month is explicit: Open WebUI free with branding intact, enterprise license for white-label/Terminals; Dify Apache-plus bars multi-tenant SaaS without commercial authorization; Onyx marketing pushes permission-inheriting connectors as the reason to leave upload-only RAG. For Narrowstack Core (ADR-003 one VM, Core owns semantics + ACL), that argues for a thin MCP-callable chat shell and against adopting a second ingestion/ACL product as source of truth.

KEY PATTERNS from the research:

1. **Chat UI heat ≠ enterprise RAG depth** - Open WebUI / LibreChat / AnythingLLM dominate "self-host ChatGPT" discourse; Onyx / RAGFlow / Dify own "connectors, parsing, workflows."
2. **Hermes-class agents are rising as personal ops harnesses** - skills loop, messaging gateways, BYO model - weak multi-user SSO/ACL story.
3. **MCP is the integration language of the month** - LibreChat and LobeChat win praise when tools matter; Open WebUI still wins on install/UX.
4. **Composed stacks are normal** - RAGFlow or Dify behind Open WebUI via OpenAI-compatible APIs; chat UI is not the retrieval engine.
5. **Stars are noisy** - Hermes ~248k stars / huge issue count on a young repo: use architecture fit, not popularity, for diligence.
6. **Coverage gaps this run** - X skipped; Reddit/TikTok partial; Instagram error; thin last-7-day cluster density (54/132).

---
✅ All agents reported back!
├─ 🟠 Reddit: 17 threads │ 12,987 upvotes │ 2,661 comments │ ⚠ partial after 17 items: HTTP 429: Too Many Requests (run doctor for fixes)
├─ 🎵 TikTok: 22 videos │ 233,201 views │ 9,020 likes │ ⚠ partial after 22 items: HTTP 404: Not Found (run doctor for fixes)
├─ 🧵 Threads: 9 posts │ 888 likes
├─ 📌 Pinterest: 11 pins
├─ 🟡 HN: 21 storys │ 607 points │ 522 comments
├─ 🐙 GitHub: 9 items │ 895,339 stars │ 48,596 comments
├─ ⛏️ Digg: 36 clusters │ 142 posts │ 108 authors
├─ 📊 Polymarket: 1 market │ US government bans an open source 8.0%
├─ 🌐 Web: 17 pages - pub.towardsai.net, pinggy.io, markaicode.com, press.farm, hermes-agent.nousresearch.com, GitHub, aicybr.com, datastackhub.com
├─ 🗣️ Top voices: r/LocalLLaMA, r/ChatGPTCoding, r/selfhosted
└─ 📎 Raw results saved to ~/Dev/agent-workflows/var/last30days/self-hosted-open-source-ai-chat-rag-agent-harness-open-webui-librechat-dify-anythingllm-hermes-raw-v3.md
---

Want a deeper dive on any one candidate (LibreChat MCP wiring, Onyx EE ACL, Hermes skill loop), or a head-to-head `/last30days LibreChat vs Open WebUI`?
