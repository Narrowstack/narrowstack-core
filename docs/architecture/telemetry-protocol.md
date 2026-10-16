---
kind: architecture
slug: telemetry-protocol
date: 2026-08-31
verified: 2026-08-31
---

# Telemetry protocol — phone-home

**Summary:** Consent-first telemetry with a customer-controlled kill-switch. Outbound-only — the customer's VM initiates every connection.

---

## Load-bearing decision

**Outbound only.** Narrowstack holds no inbound path into the customer VM. Severance is a local act; re-establishment requires a new customer grant.

---

## Grant categories

Consent is per category, never global.

| Tier | Name | Contains | Never contains |
|---|---|---|---|
| T0 | Heartbeat | Alive, version, last pipeline timestamp | Business data |
| T1 | Operational health | Run outcomes, dbt tests, redacted traces | Metric values, rows |
| T2 | Metric telemetry | Aggregate metric values (egress class A) | Row data |
| T3 | Support access | Time-boxed, PIN-gated, audited human session | Outside session scope |

**Never grantable:** row records, secrets, credentials, raw payloads, private-schema data.

T3 uses customer-initiated reverse tunnel — if implementation cannot hold that shape, cut T3 before weakening outbound-only.

---

## Grant semantics

- Per category, with expiry; T3 never standing
- No permanent allowlist (parallel to approval cards)
- Grants authoritative on customer instance; admin plane mirrors
- Grant carries one-sentence purpose in audit log

---

## Kill-switch (six properties)

1. **Local** — works offline, no Narrowstack cooperation
2. **Destructive** — destroys outbound credential, not a honor-system flag
3. **Not re-establishable by us** — no inbound path
4. **Non-degrading** — pipelines, dbt, MetricFlow, warehouse keep running (M0 chat exception documented on switch)
5. **Verifiable** — instance shows tether state and outbound attempts
6. **Dead-man default** — loss of contact never degrades customer

---

## Payload preview and audit

- Render real sample payload from customer data before any grant
- Append-only audit log on customer instance first; exportable without support ticket
- Redaction runs in VM before transmission
- Divergence between customer log and mirror = security incident

---

## Export-first fallback

If majority refuse tether: signed telemetry bundle on customer schedule, same categories and redaction, customer transmits out of band. Build payload generator/redactor as dual-mode component now.

---

## Manifest integration

```yaml
control_plane:
  enabled: false
  phone_home_grants: []
telemetry_grants: []   # default heartbeat only when enabled
```

Remote ACL policy push requires explicit consent grant; local kill-switch overrides.

---

## Acceptance criteria

1. No grants → boundary capture shows T0 only, no business data
2. Revoke with network blocked → credential destroyed, not re-established by Narrowstack
3. Post-revoke pipeline, dbt, `mf query` succeed
4. Customer exports full audit log unaided
5. T3 requires live unexpired grant; self-closes
6. Every category shows sample payload before grantable

## Why it matters commercially

Risky assumption: buyers who bought "own your data" will consent to managed access at all. Majority refusal of any tether kills the tether as designed and forces the export-first fallback; refusing any tether is already an ICP disqualifier. The goal is not to collect telemetry but to build the version an ownership buyer signs, with the fallback built in the same breath.

## The plain-English version

If it cannot be said aloud without qualification, change the design, not the wording.

- We can see that your system is running, and nothing else, unless you say otherwise.
- Anything more is something you turn on, one thing at a time, and you can see exactly what it sends first.
- We never see individual records, ever, and no setting changes that.
- When a person here needs to look inside, you approve that person, that time. It expires by itself.
- You can cut us off from inside your own system, without calling us. Everything of yours keeps running.
- You have your own copy of the log of everything we did, and you can take it with you.

## Testing the consent assumption

Five Mom Test interviews with current accounts. Show the plain-English list and a sample payload, then ask which of the four tiers they would switch on and which would make them walk. "Would you accept monitoring?" measures politeness. Record refusals by tier: refusals concentrated in T2 and T3 while T0 and T1 pass mean a smaller tether, not a dead one.
