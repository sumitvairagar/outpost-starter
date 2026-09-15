# What is Outpost?

**One sentence:** Outpost is a members-only directory website for startup founders at T-Hub, where T-Hub staff curate the listings and founders browse them.

It is a curated Yellow Pages with a login. Nothing transactional happens *inside* it — every "do something" button links out (cal.com, the corporate's form, the government portal, the partner's site). Booking, applications, messaging, payments, scoring: all explicitly parked.

Read this first, then the spec (`Outpost-Prod-Spec.pdf`). The spec is module-by-module and half of it is "what we won't build"; this page is the shape.

---

## 1. Two sides of one site

```mermaid
flowchart LR
    subgraph founder["Founder side · login required"]
        direction TB
        F1[Sign up: Google / LinkedIn / email]
        F2[Onboarding: name, startup, stage, sector, city]
        F3[Home + Founder of the Day spotlight]
        F1 --> F2 --> F3
        F3 --> L1[Mentors]
        F3 --> L2[Challenges]
        F3 --> L3[Grants]
        F3 --> L4[Benefits · V2]
        F3 --> L5[Talent pool · V2]
    end

    subgraph admin["Admin side · one shared T-Hub login"]
        direction TB
        A1[Grants CRUD]
        A2[Challenges CRUD]
        A3[Partners + Offers CRUD]
        A4[Mentor approval queue · V2]
        A5[Founder of the Day picker · V2]
    end

    A1 -- publishes --> L3
    A2 -- publishes --> L2
    A3 -- publishes --> L4
    A4 -- approves --> L1
    A5 -- schedules --> F3

    L1 -- "Book a call" --> X1([cal.com])
    L2 -- "Apply now" --> X2([corporate's form])
    L3 -- "Go to source" --> X3([government portal])
    L4 -- "How to claim" --> X4([partner site])
    L5 -- "contact details" --> X5([email / phone])
```

Admin **writes**, founders **read**, every action **leaves the site**.

---

## 2. Every listing is the same page

Five of the six founder modules are one pattern repeated. Learn it once on Grants (Week 1), then reuse it.

```mermaid
flowchart LR
    Q[Query params<br/>filters · keyword · page · sort] --> S[Listing endpoint]
    P[(Founder profile<br/>sector · stage · city)] -. "AI: rank by relevance" .-> S
    S --> R[Paged cards]
    R --> D[Detail page]
    D --> OUT([External link])
    S -. "no matches" .-> E[Empty state]
```

| Module | Filters | Keyword over | Detail page | External action | Hidden by default |
|---|---|---|---|---|---|
| Mentors | expertise (multi), stage, sector | name, headline, expertise | yes | cal.com link | — |
| Challenges | sector, theme, corporate, status | title, problem statement | optional (some have none) | Apply URL | closed stay visible, marked |
| Grants | issuing body, type, stage, sector, amount band, deadline bucket | name, issuing body, summary | yes | source URL | expired |
| Benefits (V2) | category, partner | partner name, headline | yes | claim link/code | expired |
| Talent pool (V2) | role, skills, experience, location, availability | name, role, skills | resume page | contact details | signed-in only |

"Integrated AI" = each listing has a *recommend for me* mode that ranks results using the founder's profile. A smarter search, not a chatbot.

---

## 3. Data model — the member spine

The founder's profile is the one table everything hangs off. Nothing else references anything else.

```mermaid
erDiagram
    FOUNDER ||--o{ SIGN_IN_METHOD : "one account, many providers"
    FOUNDER ||--o| ENRICHED_PROFILE : "V2: pitch deck, bio, links"
    FOUNDER ||--o{ SPOTLIGHT_SCHEDULE : "V2: Founder of the Day"
    FOUNDER }o--|| STAGE : ""
    FOUNDER }o--|| SECTOR : ""

    MENTOR }o--o{ EXPERTISE_TAG : ""
    MENTOR ||--o| MENTOR_APPLICATION : "V2: pending/approved/rejected"

    CORPORATE_CHALLENGE }o--|| SECTOR : ""

    GRANT }o--o{ STAGE : "eligible stages"
    GRANT }o--o{ SECTOR : "eligible sectors"

    PARTNER ||--o{ OFFER : "V2: one partner, many offers"

    CANDIDATE }o--o{ SKILL : "V2"

    FOUNDER {
        uuid id
        string email
        string founder_name
        string startup_name
        string city
        string website
        bool onboarded
        enum role "FOUNDER | ADMIN"
    }
    MENTOR {
        uuid id
        string name
        string headline
        string bio
        string calcom_url
        enum status "SEEDED | PENDING | APPROVED | REJECTED"
    }
    CORPORATE_CHALLENGE {
        uuid id
        string corporate_name
        string title
        text problem_statement
        date deadline
        string apply_url
        bool published
        enum status "OPEN | CLOSED"
    }
    GRANT {
        uuid id
        string name
        string issuing_body
        enum type "GRANT | SUBSIDY | SCHEME | INCENTIVE"
        string amount_range
        date deadline "null = rolling"
        string source_url
        bool published
        bool expired
    }
```

Note what is *absent*: no bookings, no applications, no messages, no claims. Those tables would exist in a transactional product; here the transaction happens elsewhere. The spec says the spine must let future modules attach records "without migrating the spine" — that is why `ENRICHED_PROFILE` is its own table, not columns on `FOUNDER`.

---

## 4. The only things that happen on a clock

```mermaid
flowchart LR
    C1[Every night] --> J1[Close challenges past deadline]
    C1 --> J2[Expire grants past deadline]
    C2["00:00 IST daily"] --> J3[Switch homepage spotlight to today's scheduled founder<br/>none scheduled → keep the most recent]
```

Three scheduled jobs. That is the entire "backend logic" beyond CRUD, filtering and auth.

---

## 5. V1 vs V2

Nothing exists yet. V1 and V2 are two releases of the same product inside this engagement.

| | V1 · Phase 1 | V2 · Phase 2 |
|---|---|---|
| Profile | basic fields | + pitch deck, bio, links |
| Mentors | seeded list, cal.com | + apply form, admin approval |
| Challenges | complete | — |
| Grants | complete | — |
| Admin | grants, challenges, partners, offers | + mentor queue, Founder of the Day |
| Benefits | — | new |
| Talent pool | — | new |
| Founder of the Day | — | new |

V1 = the site works. V2 = the site has more lists and the profile grows.

---

## 6. What the backend actually is

Strip the prose and you have:

- **Auth:** 3 sign-in methods → 1 account; email verification; password reset; forced onboarding; FOUNDER vs ADMIN
- **Six listing endpoints** with filters, keyword search, pagination, sort, AI ranking
- **Admin CRUD** with publish/unpublish for 5 content types
- **One approval workflow** (mentor applications)
- **One file upload** (pitch deck) to object storage
- **Three scheduled jobs**
- **One external API integration** (the LLM)

Broad, not deep. That is why it fits in four weeks — and why every one of those bullets is an interview topic.
