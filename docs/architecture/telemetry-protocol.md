---
kind: architecture
slug: telemetry-protocol
date: 2026-08-31
verified: 2026-08-31
wiki: operating-system/working/core-telemetry-protocol.md
---

# Telemetry protocol — phone-home

**Wiki:** `operating-system/working/core-telemetry-protocol.md` (strategy canon)

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
