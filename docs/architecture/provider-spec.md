---
kind: architecture
slug: provider-spec
date: 2026-08-19
verified: 2026-10-16
---

# Core spec — the polymorphic AI provider

**Summary:** how Core lets a customer bring their own AI, route to their own vendor, or run fully local, while the built-in agent stays first-line only. Owned by Core per the component boundaries: one abstraction, and no surface talks to a model vendor directly.

The component boundary table makes this Core's, with one rule attached: **one abstraction, and no surface talks to a model vendor directly.** The platform vision carries the same as a standing constraint. This section turns that rule into a contract.


## 1. Two seams, not one

The word "provider" hides two separate contracts that get conflated, and conflating them is how surfaces end up coupled to a vendor.

- **The tool contract:** what the agent is permitted to do. Owned by Core. This is the bounded-tool facade ADR-001 requires, and it is what makes the runtime swappable later instead of rewritable.
- **The provider contract:** which model answers, under whose account, inside whose network boundary. Owned by Core.

Every surface (the chat GUI, admin document generation, any automation) depends on both contracts and on nothing else. No surface imports a vendor SDK. No surface handles a vendor key. No surface parses Hermes-shaped events. The consequence worth stating plainly: **the facade is not a nice-to-have refactor, it is the thing that makes "polymorphic" true**, and it is a Must in section 10.

**The v0 tool inventory.** A tool contract that is described but never enumerated is a name, not a contract, so here is the list a person can read. Ten operations. Every one declares its egress class (section 3) statically, at definition time, and the facade refuses any call whose declared class exceeds what the active provider mode allows. This is the enforcement point for section section 3 and the reason its acceptance criteria are testable at all.

| Tool | Returns | Egress class | Approval card | Refuses by |
|---|---|---|---|---|
| `list_metrics` | Metric names and definitions | S | No | — |
| `describe_model` | Columns, types, and `persist_docs` comments | S | No | Returning "no such model", never a plausible guess |
| `list_sources` | Source registry and load-ledger freshness | S | No | — |
| `query_metric` | Aggregate rows from `mf query` | A | No | Returning "no such metric", never falling back to raw SQL |
| `validate_metric` | Tie-out result and variance against source | A | No | Reporting "no validator", never reporting a pass |
| `fetch_rows` | Individual records | **R** | **Yes** | Executing inside the VM only; never marshalled to an external provider |
| `run_pipeline` | Load status for one source | S | **Yes** | Declining while a load is in flight |
| `run_transform` | `dbt build` / `parse` status | S | **Yes** | Declining if the allowlist check (the allowlist section of the packaging spec) is failing |
| `draft` | Generated text | Class of its inputs | **Yes** to send, no to draft | — |
| `escalate` | Handoff reference and the context a human needs | S | No | Never. Escalation is never gated (principle 4) |

Four rules that travel with the table:

1. **Static classification.** A tool's egress class is a property of the tool, not of the call. A tool whose class depends on its arguments gets split into two tools.
2. **Unknown tool is a refusal, not an improvisation.** The facade has no passthrough.
3. **Approval cards attach at the facade**, above the runtime and below the surface, so every surface inherits the same approval semantics and no surface can opt out of them.
4. **The list is versioned.** Adding a tool is a minor version; changing a signature, a class, or an approval requirement is a breaking change and follows 8.10.

Ten tools is a v0, deliberately. The test of whether it is the right ten is section 9's skeleton: if a step needs an eleventh, the list was wrong and it grows by decision rather than by drift.

## 2. The four provider modes

| Mode | Whose account | Where the model runs | Kill-switch independent? | Capability |
|---|---|---|---|---|
| **M0 — Narrowstack default** | Ours | Vendor, reached through a Narrowstack gateway | **No** (see section 4) | Highest |
| **M1 — Bring your own key** | Customer's | Vendor, reached directly from the customer VM | Yes | Highest |
| **M2 — Customer vendor routing** | Customer's | The customer's own endpoint: their enterprise model contract, their self-hosted model | Yes | Depends on their model |
| **M3 — Fully local** | None | Inside the customer's own Core VM | Yes | Lowest, and honestly so |

M0 exists because most owner-operator customers will have no opinion and no vendor account, and asking them to get one is friction at exactly the wrong moment. M2 and M3 exist because the Segment B buyer will ask, and "you cannot" is a lost deal.

**Mode is per tenant, set at provision time, changeable without redeploying.** Switching modes must not require re-modeling, re-ingesting, or a new instance.

**Fallback is configured in both directions, and the direction is a customer choice, not a default.** A hosted endpoint is usually the more capable leg and a local one the more sovereign leg, and which of those is treated as primary is exactly the trade the buyer is making. So: M0 or M1 with a local fallback keeps the agent answering when the vendor is unreachable; M3 with a hosted fallback trades sovereignty for capability on hard questions and **must not fire silently**, because a fallback that quietly sends a class-A payload to a vendor the customer did not choose is the egress policy in section 3 being violated by a retry. Every fallback hop is logged, and any hop that changes the egress boundary requires a standing grant to have been given in advance.

## 3. What leaves the boundary: the egress classes

"Own your data" is decided by what crosses the VM boundary, so the provider design has to say so explicitly rather than implying it. Three classes:

| Class | What it is | Why it exists |
|---|---|---|
| **S — Schema** | Table and column names, column comments, metric definitions | This is precisely what `persist_docs` puts in Postgres, and it is what the agent needs to not hallucinate |
| **A — Aggregate** | Metric values returned by `mf query` | The answer to a question |
| **R — Row** | Individual records | Almost never needed to answer an operational question |

**Default policy, all modes:** Class S may leave. Class A may leave only on the path required to answer the question asked. **Class R never leaves the customer VM** unless the provider endpoint is inside the customer's own boundary (M2 or M3), or the customer grants a scoped, expiring exception through the same consent mechanism as section 7.

**The conversation is a fourth thing, and it is the leak nobody plans for.** Under M0 and M1 the model composing the answer sits at a vendor, so the chat transcript crosses the boundary with it: the question as typed, anything the user pasted in, and whatever the model was shown in order to answer. A user who pastes an invoice into chat has just sent class R through a door class R is not allowed through. So: **chat context is classified per message, at the boundary, not per session**, and a message classified R is either answered inside the VM by the skills layer or refused with a reason. A design that classifies query results carefully and lets the conversation carry anything has not implemented the policy, it has decorated it.

This default is the thing that makes M0 and M1 defensible to a buyer who bought ownership: what reaches the vendor is the shape of their business, not its contents. It is also a real constraint on the agent's design, because a class of questions ("show me the five invoices behind that number") wants Class R. Those get answered **inside** the VM by the skills library rather than by the model, with only the aggregate crossing back. If that turns out to be too limiting in practice, the honest response is to change this policy in writing, not to quietly widen it.

## 4. The M0 consequence nobody has stated yet

Under M0, the customer's VM cannot hold a Narrowstack API key, because the VM is under the customer's control and a key in it is a key we have given away. So M0 routes through a Narrowstack-operated gateway.

That gateway is on our side of the tether. **Therefore: exercising the section 7 kill-switch disables the built-in agent under M0.** It does not touch the warehouse, the pipelines, the models, or the metrics, all of which keep running headless, but the chat surface loses its brain.

This is not a defect to hide, it is a fact to sell against: a customer who wants their agent to survive severing all contact with Narrowstack picks M1, M2, or M3, and we should say so in the contract, in the docs, and on the provisioning screen. Selling M0 as "own your data" without stating this would be the exact class of claim that does not survive scrutiny, which is what the personas page already warns backfires with the technical buyer.

## 5. What the built-in agent is, and is not

- **Is:** first-line. It answers questions from the semantic layer, drafts, and proposes actions. **Self-contained and self-hosted are mode-dependent, not properties of the agent** (the self-hosted-agent finding in [vault findings](2026-08-19-vault-findings.md)): the tool contract, the skills, the semantic layer, and the approval loop are always in the customer's VM; only the model is not, and only under M0 and M1.
- **Is not:** a do-everything assistant. Escalation to a human is a feature (principle 4).
- **Acts only through approval cards:** Approve Once / Approve for Session / Deny, and **no permanent allowlist**. This is inherited as a hard rule and is not a default to be tuned later. Session approvals expire with the session.
- **Never fabricates.** A missing metric is reported as missing. This is already the repo's ground rule and it becomes a provider-layer requirement: a provider adapter that cannot ground an answer returns "I do not have this", not prose.

## 6. Skills stay vendor-neutral

The skills library is the extension mechanism and the most valuable thing to keep portable. Requirement: a skill expresses intent and tool calls; **vendor dialect lives only in the provider adapter.** If a skill contains a vendor-specific prompt format, the abstraction has already leaked. The existing delivery-practice Claude Skills migrate under this umbrella rather than beside it.

## 7. Key custody

- One key belongs to exactly one tenant and one mode. Keys are per instance, never committed, following the existing `.secrets/` one-file-per-secret pattern.
- **No Narrowstack-account key is ever placed in a customer VM.** That is what the M0 gateway is for.
- Centralizing the AI account and API key is an open security task, and credential handling already has to land before the Core v0 pair-build (roadmap, near-term 7). This section states the requirement; the mechanism comes from the [secrets working set](../working/secrets-management/README.md) and its pending decision record, and Core does not invent a second one.

## 8. A commercial question hiding in M0

Under M0, Narrowstack is intermediating model access for a customer. That is a terms-of-service question with the model vendor, not only an engineering one, and ADR-001 already flags third-party host restrictions as a live risk. Before M0 ships to a paying customer, someone reads the vendor terms. Owner: Tucker. This is cheap to check and expensive to get wrong.

## 9. Acceptance criteria

1. A surface can be pointed at a different provider mode with a configuration change and no code change.
2. `grep` across all surface code finds zero vendor SDK imports and zero API keys.
3. The same question, asked in M0 and in M3, returns the same metric value (capability differs; the number does not, because the number comes from `mf query`).
4. Under M0, exercising the kill-switch disables chat and leaves pipelines, dbt, MetricFlow, and headless access running. Verified by test, not by assertion.
5. Class R egress is blocked by default, and the block is testable.

---
