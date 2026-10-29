# Outpost Phase 2 — Product Requirements

> **Read this first, then ask questions.**
> This document describes what needs to be built. It does not tell you how to build it.
> Your job is to understand the business problem, ask the right questions, propose an approach, discuss it with the stakeholders, and then build it.

---

## 1. Background

Outpost V1 is live. Founders are signing up, browsing grants, exploring challenges, and connecting with mentors. T-Hub staff are managing the content through the admin panel.

The product has proved its value. Now the challenges are different.

T-Hub is preparing to showcase Outpost at a national startup event. The platform needs to handle a significant increase in traffic. Founders are giving feedback that they want to be kept informed, not just browse passively. T-Hub's compliance team needs a full audit trail of every admin action. And the T-Hub technology team is planning future products — an events platform, a mentorship marketplace — that will share Outpost's infrastructure. The way Outpost is built today, everything is wired together; that has to change.

This document describes the new requirements. Some are clear. Some are deliberately open — they need a discussion with the stakeholders before implementation begins.

**One rule:** before you write a line of code for any module, you must be able to answer: *why is this the right solution to the business problem described?*

---

## 2. Business Goals

- **Increase founder engagement**: Founders should find Outpost more useful and return to it regularly.
- **Reduce admin effort**: T-Hub staff spend hours manually entering content they receive in bulk; this has to change.
- **Build trust and accountability**: Every action on the platform must be traceable.
- **Scale for a public launch**: The platform must handle a surge of concurrent users without degrading.
- **Lay the foundation for multiple products**: Future T-Hub products will share this platform; the architecture must support that without requiring everything to be rebuilt.

---

## 3. Module P2-1 — Founder Engagement & Insights

### What the stakeholders said

> *"We publish grants and challenges but we have no idea if founders are actually reading them. Are they clicking the apply links? Which grants are popular? We are flying blind."*

> *"But this data must not slow down the platform. If founders experience any delay because of analytics, that is unacceptable."*

### Requirements

T-Hub administrators need a reporting view that shows:

- How many times each grant, challenge, and mentor listing has been viewed
- How many times the external action link (apply URL, source URL, cal.com) has been clicked through
- Engagement trends over time — weekly and monthly aggregates
- A ranked view of top-performing content by views and clicks
- Breakdown by founder sector and stage (which audience is most engaged with which content)

This data is for T-Hub internal use only. Founders do not see it.

```
Recording an engagement event must not slow down the founder's request.
A founder browsing the grants list must not wait for analytics to complete.
```

### What we will not build

- Per-founder engagement history visible to other founders or partners
- A/B testing or content experiments
- Real-time live dashboards — daily aggregates are sufficient for now

### Open for clarification

- How long should raw engagement data be retained before archiving or deletion?
- Should clicking an external link be tracked server-side (redirect via our platform) or is a client-side approach acceptable?
- Who has access to the analytics dashboard — T-Hub admin only, or read-only access for certain partners as well?

---

## 4. Module P2-2 — Smart Notification Engine

### What the stakeholders said

> *"Founders sign up once and then forget about us. We publish a great government grant scheme and nobody sees it for two weeks. We need a way to tell founders when something relevant to them has been published."*

> *"But we do not want to spam them. Too many emails and they will unsubscribe. It needs to be relevant and controllable."*

> *"And whatever you build, it must not affect the rest of the platform. If the notification system has a problem, founders must still be able to log in and browse."*

### Requirements

**Founder notification preferences:**

- Founders can opt in or out of notifications per content type: grants, challenges, mentors
- Founders can choose their notification frequency: immediately when published, or a weekly digest
- Default for all founders: weekly digest, all content types enabled
- Preferences are editable from the founder profile at any time

**When a notification is triggered:**

- A new grant is published that matches the founder's sector, stage, or both
- A new challenge is published that matches the founder's sector
- A new mentor is approved whose expertise overlaps with the founder's sector
- The weekly digest aggregates all matched content published during that week

**Delivery:**

- Email is the primary delivery channel
- Each notification includes a brief summary of the matched content and a direct link
- The system must retry failed deliveries — a delivery failure is never silently dropped
- Weekly digests are sent at a consistent, configurable time (T-Hub to configure)

**Behaviour under load and failure:**

```
Sending notifications to 5,000 matching founders after a grant is published
must not delay the admin's publish action or affect the response time of the platform.

If the email service is unavailable, undelivered notifications must be queued
and delivered when the service recovers. No notifications are lost.

If the notification system itself is down, founders can still log in,
browse, and use every other feature of the platform without interruption.
```

### What we will not build

- Push notifications (mobile or browser)
- SMS notifications
- In-app notification inbox
- Per-grant or per-challenge notification toggles (only per content type)

### Open for clarification

- If a grant is updated after a notification is already sent, should a second notification go out?
- Can T-Hub admins trigger a manual notification to all relevant founders for a time-sensitive opportunity?
- Is there a preferred email delivery provider, or is SMTP (Mailpit for local) sufficient for now?

---

## 5. Module P2-3 — Bulk Content Operations

### What the stakeholders said

> *"Every quarter, the Ministry of MSME and other government bodies release an Excel file with 200 to 300 new grants and schemes. Right now, someone has to enter each one by hand. That takes days. Can we just upload the file?"*

> *"When something goes wrong mid-import, we need to know exactly what failed and why. Not just 'something went wrong.' Which row? Which field? What was the problem?"*

> *"And we do not want to wait on a loading screen while 300 rows import. That is not acceptable."*

### Requirements

**Bulk grant import:**

- Admin can upload a file (the team must decide and document the supported format)
- The system validates every row before importing any of them
- If validation errors exist, the admin receives a clear error report: which rows failed, which field was invalid, and why
- Admin can choose to import the valid rows only, skipping failed ones, or fix and re-upload the entire file
- The import runs in the background — the admin does not wait on a loading screen
- Admin is notified when the import is complete: success count, failure count, and a downloadable error report

**Idempotency:**

- Re-uploading the same file must not create duplicate records
- The system must detect and skip records that already exist
- The team must define what makes a grant record "the same" as an existing one

**Bulk status operations:**

- Admin can select multiple grants or challenges and publish, unpublish, or expire them in a single action
- Bulk operations on up to 500 records must complete within a time that the team defines, justifies, and demonstrates

### What we will not build

- Bulk import for mentor records — mentor approval is a manual, curated process by design
- Automated scheduled fetches from government portals

### Open for clarification

- What is the expected maximum file size and row count for a single import?
- Is the import template (column names, field order) fixed, or does the admin map columns at upload time?
- Should the admin be able to preview the parsed data before confirming the import?
- What happens to a partially completed import if the server restarts mid-way?

---

## 6. Module P2-4 — Audit & Compliance Trail

### What the stakeholders said

> *"We need to know who did what and when. If a grant disappears, or something gets published when it should not have been, we need to trace it back. This is non-negotiable for our compliance team."*

> *"It does not need to be fancy. Just: what happened, who did it, when, and what it looked like before and after."*

> *"And it must not slow anything down. If someone is entering grants and the audit system adds delay, that is a problem."*

### Requirements

Every admin action that creates, modifies, publishes, unpublishes, expires, or deletes content must be automatically recorded.

Each audit record captures:

| Field | Description |
|---|---|
| Actor | The admin who performed the action |
| Action | What was done (e.g., PUBLISHED, UPDATED, DELETED) |
| Entity type | What kind of record was affected (Grant, Challenge, Mentor, etc.) |
| Entity ID | The specific record |
| Timestamp | UTC, precise to the millisecond |
| Before snapshot | The state of the record before the action |
| After snapshot | The state of the record after the action |

Audit records are **immutable**. They cannot be deleted or modified through any part of the application.

Admins can view the audit trail filtered by date range, actor, entity type, and action.

```
The audit trail must not measurably slow down the operations it records.
An admin publishing a grant must not experience any additional delay
because the audit system is recording it.
```

**Scope of audit:**

- Grants: create, update, publish, unpublish, expire, delete, bulk import (one record per imported row)
- Challenges: create, update, publish, unpublish, delete
- Mentors: approve, reject
- Partners and Offers (if implemented in Phase 1)

**Out of scope:**

- Founder profile changes
- Login and logout events
- Read operations: viewing, searching, browsing

### Open for clarification

- How long should audit records be retained?
- Should the audit log live in the same database as the main application, or in a separate store?
- For the before/after snapshot: full copy of the entity as JSON, or only the changed fields?
- Should bulk imports produce one audit record per imported row, or one record for the entire import job?

---

## 7. Module P2-5 — Platform Performance & Reliability

### What the stakeholders said

> *"We are presenting Outpost at a national startup event. There will be a live demo and we expect a large number of founders to sign up and use the platform on the same day. We cannot have the site slow down or go down during that. This is a hard requirement."*

> *"Right now, when the government portal is down, the 'Go to Source' button just fails silently. Founders have no idea what is happening. We need better behaviour than that."*

> *"I want to see evidence that the platform can handle the load. Not just 'it worked on my laptop.'"*

### Performance targets

The team is responsible for defining, measuring, and validating performance targets — not just assuming they are met.

The expected deliverables are:
- A set of agreed performance targets (response times, concurrent user count) discussed and signed off with stakeholders **before** testing begins
- Load test results demonstrating those targets are met under simulated realistic load
- A written summary identifying what was measured, what was optimised, and why

**The targets are deliberately not specified here.** The team must propose them based on an estimate of event attendance, expected usage patterns, and what is realistic. The stakeholders will challenge those estimates.

### Reliability requirements

- The notification system (Module P2-2) must not degrade listing or authentication performance even under high notification volume
- If an external dependency — email provider, LLM service — is unavailable, the rest of the application must continue to function normally
- Founders must never see a raw stack trace or internal error message
- Slow or unresponsive third-party services must not cause the main application to hang or time out in a way that affects founders

### What we will not build

- CDN integration
- Geo-distributed deployment
- Auto-scaling infrastructure

### Open for clarification

- What is the estimated peak concurrent user count for the event?
- What is the acceptable response time for the grants listing endpoint under that load?
- Are there specific endpoints that T-Hub considers more critical than others for the event demo?

---

## 8. Module P2-6 — Platform Architecture Evolution

### What the stakeholders said

> *"Outpost is just the first product we are building on this platform. We plan to build a mentorship marketplace and an events platform next year using the same foundation. The way it is built today, everything is tied together. A change to the notifications code can break the grants listing. We need it to be more modular."*

> *"Different teams should be able to work on different parts without stepping on each other. And if one part needs to handle more traffic than another, we should be able to scale it independently."*

> *"I want to see a proposal before you build anything. Walk us through what you are thinking and why."*

### Requirements

The team must propose, discuss with stakeholders, and agree on an architecture that:

- Allows different parts of the platform to be **deployed independently** — a change to notifications should not require a redeployment of the grants functionality
- Allows different parts to be **scaled independently** — the content browsing experience can be scaled separately from the admin tools
- Enables future T-Hub products to **reuse core capabilities** (authentication, notifications, content) without duplicating them
- Presents a **consistent experience** to the end user — a single login, a coherent API surface

**The team is expected to:**

1. Present a proposed architecture to stakeholders with clear service boundaries and rationale for each boundary
2. Identify what can be extracted from the existing codebase and what should remain
3. Explain how services communicate with each other and why
4. Address how a user's authentication and authorisation works across multiple services
5. Present the trade-offs of the proposed design — what does this approach make easier, and what does it make harder?
6. Propose a migration path — how do you get from the current monolith to the target architecture without breaking anything?

**This is a design and decision exercise, not just an implementation exercise.**
The architecture proposal must be presented and approved before any significant implementation begins.

### Deployment requirements

Each independently deployable service must have:

- Its own build and deployment pipeline
- Independent versioning
- Health check endpoints
- Environment-specific configuration that does not require code changes to deploy to a different environment
- No secrets hardcoded in any build or deployment configuration

The team must demonstrate that a single service can be updated and deployed without affecting any other running service.

### Constraints

- Outpost V1 functionality must continue to work throughout the transition
- Existing functionality must not be broken while the architecture is being evolved
- The team must define and agree a migration strategy before beginning; big-bang rewrites are not acceptable

### What we will not build

- Full event sourcing or CQRS (unless the team proposes it and makes a compelling case)
- A service mesh (Istio, Linkerd, or equivalent)
- Multi-cloud or cloud-agnostic deployment

### Open for clarification

- Does T-Hub have a preferred cloud provider? Are there any cost constraints on infrastructure?
- How much downtime, if any, is acceptable during the migration from the current architecture?
- Is Kubernetes in scope, or is container-based deployment without an orchestrator acceptable for Phase 2?

---

## 9. Non-Functional Requirements Summary

| Area | Requirement | How to demonstrate |
|---|---|---|
| Analytics recording | Must not slow down the operation being tracked | Response time comparison with and without recording |
| Notification fan-out | Must not block the publish action | Publish response time with 5,000 matched founders |
| Notification delivery | No notifications lost on failure | Fault injection: kill email service, verify queue |
| Bulk import | Background processing, progress feedback | Demo: admin does not wait on screen |
| Audit recording | Must not measurably slow admin operations | Response time comparison |
| Listing performance | Team-defined targets, demonstrated under load | Load test report |
| Resilience | Core functions work when optional modules fail | Fault injection demo |
| Deployability | One service deployable without restarting others | Live deployment demo |

---

## 10. What we will not build in Phase 2

- Benefits, Talent Pool, Founder of the Day modules (completed in V2)
- Transactional features: bookings, payments, in-app messaging
- Mobile application
- White-labelling for other organisations
- External integrations beyond what the modules above require
- Full event sourcing or CQRS

---

## 11. Assumptions

- Outpost V2 (Benefits, Talent Pool, Founder of the Day) is complete before Phase 2 work begins
- T-Hub will provide required credentials for any external services (cloud provider, email delivery, etc.)
- A staging environment is available or will be provisioned as part of Phase 2
- Performance targets will be proposed by the team and agreed with stakeholders before load tests are run
- The architecture proposal for Module P2-6 will be reviewed and approved by stakeholders before implementation begins

---

## 12. How the team should approach this

This is not a story board. The requirements above are business problems. The team's job is to:

1. **Read and understand** — what is the real problem being described?
2. **Ask questions** — what is ambiguous? what needs a decision before you can design?
3. **Design** — what is the right technical approach? what are the trade-offs?
4. **Discuss with stakeholders** — present your approach, take feedback, reach agreement
5. **Break it into stories** — the team defines the backlog, not the lead
6. **Build, test, and demonstrate** — working software, with evidence

There is no answer key. The expectation is that you can walk a stakeholder through your reasoning and defend your decisions.
