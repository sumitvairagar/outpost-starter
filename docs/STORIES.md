# Outpost backlog – story details

Every story you build, with what 'done' means. IDs match the Project Tracker. **Core** stories are mandatory; **Optional** are the safety valve (drop only with the lead's OK).

> Conventions used everywhere: base path /api/v1; admin endpoints under /api/v1/admin/** (ADMIN role); paged responses are {content:[], page, size, totalElements, totalPages}; errors are RFC 7807 ProblemDetail with a stable `code` field; IDs are UUID; timestamps are UTC ISO-8601.

## E0 Foundation

### OP-001 · Repo from starter, branch strategy, PR template

**Week 1 · Core**

Get your own repo created from outpost-starter, cloned, and agree the git workflow you'll follow for four weeks.

**Acceptance criteria**

- [ ] Repo `outpost-<yourname>` exists, created from the template; you have push access
- [ ] `main` is protected: PRs required, CI must pass, at least one approval
- [ ] Branch naming `OP-012-short-slug`; commit messages `OP-012: what changed`
- [ ] PR template renders when you open a PR (story / what & why / AI used for / DoD checklist)
- [ ] README read end to end; `./scripts/check-env.sh` shows all green except pom.xml

**Tests**

- none – infra

**Read first**

- GitHub docs: branch protection rules
- Conventional commits (skim)

---

### OP-002 · docker-compose: Postgres 16 (+ MinIO, Mailpit)

**Week 1 · Core**

Local infrastructure running in Docker so the app has a real database from day one.

**Acceptance criteria**

- [ ] `docker compose up -d` starts postgres, minio, mailpit; `docker compose ps` shows all healthy
- [ ] You can connect with any SQL client: localhost:5432, db/user/pass `outpost`
- [ ] MinIO console opens at :9001, Mailpit at :8025
- [ ] `docker compose down -v && docker compose up -d` gives a clean DB (you will do this a lot)

**Tests**

- none – infra

**Read first**

- docker compose docs: services, volumes, healthcheck

---

### OP-003 · Spring Boot 3 skeleton, Actuator health, profiles

**Week 1 · Core**

A running Spring Boot application connected to Postgres, with environment-specific configuration.

**API / interface**

`GET /actuator/health → 200 {"status":"UP"} (includes db component)`

**Acceptance criteria**

- [ ] Project generated from start.spring.io per README (Java 21, Maven, Boot 3.x latest, listed deps); `pom.xml` at repo root; Maven wrapper committed
- [ ] Package root `com.thub.outpost`; package-by-feature layout from README
- [ ] `application.yml` with profiles: `local` (compose DB), `test` (Testcontainers – no fixed URL), `prod` (everything from env vars). No secrets in git
- [ ] Datasource configured via `SPRING_DATASOURCE_*` env vars with sensible local defaults
- [ ] `./mvnw spring-boot:run` starts on :8080 with `local` profile; `/actuator/health` returns UP with db UP
- [ ] Security temporarily permits `/actuator/health` and `/swagger-ui/**` (proper config comes in OP-017)
- [ ] `spring.jpa.hibernate.ddl-auto=validate` (never update/create) – schema is Flyway's job
- [ ] `spring.jpa.open-in-view=false`

**Tests**

- Context loads test (`@SpringBootTest`) is green – it will use Testcontainers once OP-008 lands

**Read first**

- Spring Boot reference: Externalized Configuration, Profiles
- Actuator: health endpoint

---

### OP-004 · Flyway baseline + migration conventions

**Week 1 · Core**

Every schema change from now on is a versioned SQL migration. No hand-edits, no ddl-auto.

**Acceptance criteria**

- [ ] `src/main/resources/db/migration/V1__baseline.sql` exists (may only create an `app_meta` table or be a comment)
- [ ] Naming: `V<n>__<snake_case_description>.sql`, one migration per story that touches schema, never edit a merged migration
- [ ] Flyway runs on startup; `flyway_schema_history` table visible in Postgres
- [ ] Startup fails loudly if a migration fails (default) – verify by breaking one locally, then fix
- [ ] Document the convention in `docs/CONVENTIONS.md` (short)

**Tests**

- Context loads test still green

**Read first**

- Flyway docs: naming, versioned vs repeatable
- Why ddl-auto=update is dangerous (search: 'hibernate ddl-auto production')

---

### OP-005 · Global error handling (ProblemDetail) + exception hierarchy

**Week 1 · Core**

One consistent error shape for the whole API, and a small set of domain exceptions every module reuses.

**API / interface**

`Any error → application/problem+json: {type, title, status, detail, instance, code, errors?:[{field, message}]}`

**Acceptance criteria**

- [ ] Exceptions in `common.error`: `NotFoundException(entity, id)` → 404, `ConflictException` → 409, `ValidationException` → 400, `ForbiddenException` → 403; all carry a machine-readable `code` (e.g. `GRANT_NOT_FOUND`)
- [ ] `@RestControllerAdvice` maps: those exceptions; `MethodArgumentNotValidException` → 400 with per-field `errors[]`; `HttpMessageNotReadableException` → 400; `AccessDeniedException` → 403; `AuthenticationException` → 401; anything else → 500 with no stack trace leaked
- [ ] Uses Spring's `ProblemDetail` (Boot 3), not a home-made class
- [ ] 500s are logged at ERROR with stack trace; 4xx at WARN without

**Tests**

- `@WebMvcTest` of a throwaway controller: each exception type → expected status + body shape
- Validation failure returns `errors[]` with field names

**Read first**

- Spring docs: Error Responses (ProblemDetail)
- RFC 7807

---

### OP-006 · OpenAPI (springdoc) + Swagger UI

**Week 1 · Core**

Every endpoint is discoverable and testable from the browser without Postman.

**API / interface**

`GET /swagger-ui.html, GET /v3/api-docs`

**Acceptance criteria**

- [ ] springdoc-openapi-starter-webmvc-ui added; Swagger UI loads at `/swagger-ui.html`
- [ ] API info block set (title 'Outpost API', version, description)
- [ ] JWT bearer security scheme declared so the 'Authorize' button works (used from OP-017)
- [ ] Endpoints grouped by tag per feature (`Grants`, `Admin – Grants`, …)

**Tests**

- Smoke test: GET /v3/api-docs returns 200 and contains `openapi`

**Read first**

- springdoc docs: getting started, `@Tag`, `@Operation`, security scheme

---

### OP-007 · CI: build + test on every PR

**Week 1 · Core**

Nothing merges without a green pipeline that runs your real tests against a real Postgres.

**Acceptance criteria**

- [ ] `.github/workflows/ci.yml` from starter runs `./mvnw verify` on PR and on main
- [ ] Testcontainers tests pass in CI (Docker is available on ubuntu-latest)
- [ ] Surefire reports uploaded as artifact on failure
- [ ] Branch protection requires the `build` check

**Tests**

- The pipeline itself – open a PR and watch it go green

**Read first**

- GitHub Actions: workflow syntax, setup-java caching

---

### OP-008 · Test infrastructure: Testcontainers base, data builders

**Week 1 · Core**

A reusable test foundation so every later story's tests are ~10 lines, not 60.

**Acceptance criteria**

- [ ] `AbstractIntegrationTest` (abstract, `@SpringBootTest`, `@AutoConfigureMockMvc`, `@ActiveProfiles("test")`) starts ONE shared `PostgreSQLContainer` for the whole test run (static, `@ServiceConnection` or `@DynamicPropertySource`)
- [ ] Flyway runs against the container; tests run against the real schema
- [ ] Each test class cleans the tables it touches (`@Sql` or a `TestDataCleaner`) – tests are order-independent
- [ ] `test/.../support/` holds builders: `GrantBuilder.aGrant().published().withDeadline(...)` style – add one per entity as you go
- [ ] A `TestAuth` helper that mints a valid JWT for a founder / admin (fill in at OP-017)
- [ ] Unit tests (Mockito) don't start Spring at all – keep them fast

**Tests**

- `ContextLoadsIT` extends the base and passes
- One repository test proving Flyway applied (query `flyway_schema_history`)

**Read first**

- Testcontainers: Spring Boot integration, `@ServiceConnection`
- Spring Boot testing: `@SpringBootTest` vs `@WebMvcTest` vs `@DataJpaTest`
- Test Data Builder pattern

---

## E2 Grants & Schemes

### OP-009 · Grant entity + migration

**Week 1 · Core** · Spec p.5–6 Grants & Schemes

Model a grant/scheme exactly as the spec describes it, with the right indexes for the listing filters.

**Acceptance criteria**

- [ ] Migration creates `grant` with: id uuid, name, issuing_body, issuing_body_type enum (CENTRAL|STATE|OTHER), type enum (GRANT|SUBSIDY|SCHEME|INCENTIVE), amount_min/amount_max numeric nullable, amount_display text, deadline date nullable (null = rolling), summary text, eligibility text, what_is_funded text, how_to_apply text, source_url, published bool, expired bool, created_at/updated_at
- [ ] Join tables `grant_stage` and `grant_sector` referencing lookup tables (create simple `stage` and `sector` tables now with seed rows; OP-025 makes them admin-editable)
- [ ] Enums stored as VARCHAR (`@Enumerated(STRING)`), never ORDINAL
- [ ] Indexes on: published+expired, deadline, issuing_body_type, type
- [ ] `Grant` JPA entity with `@ManyToMany` to Stage/Sector; no Lombok `@Data` on entities (equals/hashCode trap – explain why in the PR)

**Tests**

- `@DataJpaTest`/IT: save a grant with two stages and two sectors, reload, relations intact

**Read first**

- Spring Data JPA: entity mapping, ManyToMany
- Vlad Mihalcea: 'best way to map ManyToMany' and 'why equals/hashCode on entities is tricky'

---

### OP-010 · Admin: grants CRUD + publish/unpublish/expire

**Week 1 · Core** · Spec p.5–6

T-Hub staff can maintain the grants directory without a developer.

**API / interface**

`POST /api/v1/admin/grants · GET /api/v1/admin/grants (all, incl. unpublished/expired, paged) · GET /api/v1/admin/grants/{id} · PUT /api/v1/admin/grants/{id} · POST /api/v1/admin/grants/{id}/publish · POST /api/v1/admin/grants/{id}/unpublish · POST /api/v1/admin/grants/{id}/expire · DELETE /api/v1/admin/grants/{id}`

**Acceptance criteria**

- [ ] Request DTO validated: name, issuing_body, type, summary, source_url (valid URL) required; stages/sectors are lists of ids that must exist (400 with field error otherwise)
- [ ] New grants are `published=false`; publish/unpublish flip the flag; expire sets `expired=true`
- [ ] PUT is full replace; unknown id → 404 `GRANT_NOT_FOUND`
- [ ] Admin list shows everything with a `status` filter (published|draft|expired)
- [ ] Until OP-027 lands, admin endpoints are open – add a TODO and a test that will fail once security is on (then fix it)

**Tests**

- MockMvc IT: create → 201 + Location header; invalid body → 400 with errors[]; publish → visible in founder listing; 404 path

**Read first**

- Spring MVC: `@Valid`, `ResponseEntity.created()`
- Bean Validation constraints list

---

### OP-011 · Founder listing: filters

**Week 1 · Core** · Spec p.5

The founder-facing grants page, with every filter the spec lists, implemented as composable Specifications.

**API / interface**

`GET /api/v1/grants?issuingBodyType=&type=&stageId=&sectorId=&amountBand=&deadline=&page=0&size=20`

**Acceptance criteria**

- [ ] Returns only `published=true AND expired=false` grants (default view)
- [ ] Filters, all optional and combinable (AND): issuingBodyType, type, stageId, sectorId, amountBand (UNDER_10L | 10L_50L | 50L_1CR | OVER_1CR – define bands, document them), deadline (OPEN_NOW | CLOSING_THIS_MONTH | ROLLING)
- [ ] Implemented with `JpaSpecificationExecutor` – one small Specification per filter, combined with `Specification.allOf(...)`; no if-else string building
- [ ] Response DTO per card: id, name, issuingBody, type, amountDisplay, deadline (or 'rolling'), stages[], sectors[] – never the entity
- [ ] Filtering on ManyToMany (stage/sector) does not produce duplicate rows (`query.distinct(true)` or a subquery)
- [ ] Run `EXPLAIN ANALYZE` on the generated SQL for 2 filters and paste the output in the PR

**Tests**

- IT per filter with builder data: each filter alone; two combined; unpublished/expired never appear; no duplicates with stage filter

**Read first**

- Spring Data JPA: Specifications
- Postgres: EXPLAIN basics

---

### OP-012 · Keyword search + pagination + sort

**Week 1 · Core** · Spec p.5

Founders can type what they're looking for and page through results in a predictable order.

**API / interface**

`GET /api/v1/grants?q=women+entrepreneurs&sort=deadline,asc&page=0&size=20`

**Acceptance criteria**

- [ ] `q` searches name, issuing_body, summary case-insensitively (start with ILIKE '%q%' across the three; note in PR when you'd switch to full-text)
- [ ] `q` combines with all OP-011 filters
- [ ] Pagination via `Pageable`; `size` capped at 50 (400 above); default sort `deadline asc nulls last` then `name asc`
- [ ] Sort whitelist: deadline, name, createdAt – any other field → 400 (never pass client sort straight to JPA)
- [ ] Page response envelope as per conventions

**Tests**

- IT: q matches summary; q + filter; size>50 → 400; sort=evil → 400; page 2 has different content than page 1; rolling grants sort last

**Read first**

- Spring Data: Pageable, Sort
- Why you whitelist sort fields (search 'Spring Data sort injection')

---

### OP-013 · Expired handling: hidden by default, filter to show, auto-expire job

**Week 1 · Core** · Spec p.5 'Expired entries drop off the default view'

Expired grants drop off the default view but are never lost, and expiry happens without an admin clicking.

**API / interface**

`GET /api/v1/grants?includeExpired=true`

**Acceptance criteria**

- [ ] Default listing excludes expired; `includeExpired=true` includes them, each card carries `expired: true`
- [ ] `GrantExpiryJob` runs nightly (`@Scheduled(cron)`, cron in config) and sets `expired=true` where `deadline < today` and not already expired; rolling (null deadline) never expires
- [ ] Job uses an injected `Clock` – no `LocalDate.now()` in business code
- [ ] Job is idempotent and logs how many rows it expired
- [ ] `@EnableScheduling` in a config class, not on the main class

**Tests**

- Unit test of the job with fixed Clock: expires yesterday's, leaves today's and rolling
- IT: includeExpired toggles visibility

**Read first**

- Spring: Task Scheduling
- java.time Clock and testing

---

### OP-014 · Grant detail + empty-state contract

**Week 1 · Core** · Spec p.5 'Detail page per entry'

A founder opens a grant and gets everything the spec lists, with a prominent link to the real application.

**API / interface**

`GET /api/v1/grants/{id}`

**Acceptance criteria**

- [ ] Returns: name, issuingBody, type, amountDisplay, deadline/rolling, summary (T-Hub's words), eligibility, whatIsFunded, howToApply, sourceUrl, stages[], sectors[], expired flag
- [ ] Unpublished → 404 (founders never see drafts); expired → 200 with `expired:true`
- [ ] Listing with zero results returns 200 with empty `content` and correct totals – never 404 (document this as the empty-state contract in OpenAPI)

**Tests**

- IT: published → 200 shape; draft → 404; unknown → 404; empty listing → 200 with content=[]

---

### OP-015 · Grants: full test coverage to DoD

**Week 1 · Core**

Close every gap so Grants is the reference module the other five copy.

**Acceptance criteria**

- [ ] Service unit tests (Mockito) for publish/unpublish/expire rules and validation of stage/sector ids
- [ ] Repository/Specification tests against Testcontainers for every filter and q
- [ ] MockMvc ITs for every endpoint incl. 400/404 paths
- [ ] One test deliberately broken and restored (say which in the PR)
- [ ] Coverage is not the goal; every branch of business logic has a test

**Tests**

- This story IS the tests

**Read first**

- Mockito: `@ExtendWith(MockitoExtension)`, `ArgumentCaptor`
- AssertJ

---

## E1 Member Spine

### OP-016 · Founder entity, roles, audit fields

**Week 2 · Core** · Spec p.1–2 Member spine

The identity every other module hangs off. Get the shape right now; everything references it later.

**Acceptance criteria**

- [ ] Migration: `founder` (id uuid, email unique lower-cased, email_verified bool, password_hash nullable, founder_name, startup_name, stage_id, sector_id, city, website nullable, onboarded bool, role enum FOUNDER|ADMIN, created_at, updated_at); `founder_identity` (founder_id, provider enum GOOGLE|LINKEDIN|EMAIL, provider_subject, unique(provider, provider_subject))
- [ ] `Founder` entity; `@CreatedDate/@LastModifiedDate` via `@EnableJpaAuditing` and an `Auditable` base class reused by every entity from now on
- [ ] Email is the natural key across providers: stored lower-case, unique index
- [ ] Password hash is nullable (OAuth-only founders); never expose it in any DTO

**Tests**

- Repository IT: unique email violation surfaces as `ConflictException` (translate DataIntegrityViolationException in the service)

**Read first**

- Spring Data JPA auditing
- Spec p.2 'One account per founder'

---

### OP-017 · Email/password sign-up + login → JWT + refresh

**Week 2 · Core** · Spec p.2 'Sign Up and Sign In with … email and password'

A founder can create an account and get tokens the rest of the API accepts.

**API / interface**

`POST /api/v1/auth/signup {email,password} → 201 · POST /api/v1/auth/login → 200 {accessToken, refreshToken, expiresIn} · POST /api/v1/auth/refresh {refreshToken} → new pair · GET /api/v1/me → current founder`

**Acceptance criteria**

- [ ] Password policy: min 10 chars (400 otherwise); stored with BCrypt (strength ≥ 10)
- [ ] Signup with existing email → 409 `EMAIL_TAKEN`; creates founder with `email_verified=false`, `onboarded=false`, role FOUNDER, and an EMAIL identity row
- [ ] Access JWT: HS256 (secret from env, ≥ 32 bytes), 15 min, claims sub=founderId, role, email; refresh token: opaque random, 30 days, stored hashed in `refresh_token` table, rotated on use, revocable
- [ ] Login with unverified email → 403 `EMAIL_NOT_VERIFIED` (verification is OP-018)
- [ ] `SecurityConfig`: stateless, CSRF off, CORS configured from properties, `JwtAuthFilter` before `UsernamePasswordAuthenticationFilter`, public: /auth/**, /actuator/health, /swagger-ui/**, /v3/api-docs/**; everything else authenticated
- [ ] Wrong password → 401 with generic message (don't reveal whether email exists)
- [ ] `GET /me` returns founder DTO incl. `onboarded`, never password hash

**Tests**

- IT: signup → login → /me round trip; wrong password 401; expired token 401; refresh rotates (old refresh rejected); /me without token 401
- Unit: token service sign/verify/expiry

**Read first**

- Spring Security 6: filter chain, `SecurityFilterChain` bean, stateless
- JWT (jjwt or nimbus), why HS256 secret length matters
- OWASP: password storage cheat sheet

---

### OP-018 · Email verification + email service abstraction

**Week 2 · Core** · Spec p.2 'Email sign-up includes verification'

New accounts prove they own the email before they can use the platform; email sending is swappable and testable.

**API / interface**

`POST /api/v1/auth/verify {token} · POST /api/v1/auth/resend-verification {email}`

**Acceptance criteria**

- [ ] `EmailSender` interface with `SmtpEmailSender` (Mailpit locally via spring-boot-starter-mail) and `FakeEmailSender` used in tests (captures messages)
- [ ] On signup, create `verification_token` (hashed token, founder_id, expires_at = +24h, used_at null) and send an email with the raw token link
- [ ] Verify: valid+unused+unexpired → mark founder verified, set used_at; otherwise 400 `TOKEN_INVALID`; second use → 400
- [ ] Resend: always 200 (don't leak whether email exists); rate-limit to 1/min per email
- [ ] Email sent asynchronously (`@Async` with a configured executor) so signup latency doesn't include SMTP

**Tests**

- IT with FakeEmailSender: signup sends exactly one email containing a token; verify succeeds once; expired token rejected (manipulate expires_at via repository)

**Read first**

- Spring: `@Async`, `@EnableAsync`
- OWASP: forgot password / token cheat sheet (same rules apply)

---

### OP-019 · Password reset flow

**Week 2 · Core** · Spec p.2 'password reset'

A founder who forgot their password can safely set a new one.

**API / interface**

`POST /api/v1/auth/forgot-password {email} → 200 always · POST /api/v1/auth/reset-password {token,newPassword} → 200`

**Acceptance criteria**

- [ ] Same token table pattern as OP-018 (type column RESET|VERIFY or separate table – your call, defend it), 1h expiry, single use, hashed at rest
- [ ] Reset invalidates all refresh tokens for that founder
- [ ] OAuth-only founder (no password) may set one via reset – document that this is how they add email login
- [ ] Response never reveals whether the email exists

**Tests**

- IT: forgot → email captured → reset works → old password fails, new works → token cannot be reused; unknown email still 200 and sends nothing

**Read first**

- OWASP forgot password cheat sheet

---

### OP-020 · Google OAuth2 login

**Week 2 · Core** · Spec p.2 'Google, LinkedIn'

A founder can sign in with Google and end up with the same JWT pair as email login.

**API / interface**

`GET /oauth2/authorization/google (Spring-managed) → callback → redirect to frontend with tokens, or POST /api/v1/auth/oauth/google {idToken} → JWT pair (pick one, document why)`

**Acceptance criteria**

- [ ] Spring Security OAuth2 client configured from env (`GOOGLE_CLIENT_ID/SECRET`), scope openid email profile
- [ ] Success handler: look up `founder_identity(GOOGLE, sub)`; if absent, create founder from email+name (email_verified=true because Google verified it) and the identity row
- [ ] Issue the same access/refresh pair as OP-017; new founders have `onboarded=false`
- [ ] Google account without a verified email → 403
- [ ] Lead provides the client credentials; they are never committed

**Tests**

- Unit test of the success-handler/service with a fake OidcUser: new founder created; existing identity reused
- IT of the token issuance path with a mocked user-info step

**Read first**

- Spring Security: OAuth2 Login, `OAuth2UserService`, success handlers
- OIDC vs OAuth2 (one page)

---

### OP-021 · LinkedIn OAuth2 login

**Week 2 · Optional** · Spec p.2

Second provider through the same code path – proves OP-020 was built generically.

**API / interface**

`GET /oauth2/authorization/linkedin`

**Acceptance criteria**

- [ ] LinkedIn 'Sign In with LinkedIn using OpenID Connect' registration (needs T-Hub app approval – lead handles)
- [ ] No new success-handler logic: provider is a parameter, not a copy-paste
- [ ] Same founder-lookup/creation rules as Google

**Tests**

- Same unit tests as OP-020 parameterised over provider

**Read first**

- LinkedIn OIDC docs

---

### OP-022 · One account per founder: account linking by verified email

**Week 2 · Core** · Spec p.2 'One account per founder, regardless of sign-in method'

Whatever way a founder signs in, they land in the same account. This is the spec's hard rule.

**API / interface**

`GET /api/v1/me/identities → [{provider, linkedAt}]`

**Acceptance criteria**

- [ ] On OAuth login, if no identity row matches but a founder with that (verified) email exists → attach a new identity row to that founder, do not create a duplicate
- [ ] If the existing founder's email is NOT verified → refuse linking (403 `EMAIL_UNVERIFIED_LINK`) – prevents account takeover via unverified signups
- [ ] Email signup where a founder already exists via OAuth (no password) → 409 with hint to use reset-password to add a password
- [ ] Founder can list their linked identities

**Tests**

- IT: signup+verify by email, then Google login with same email → one founder, two identities; unverified email + Google → 403; Google first then email signup → 409

**Read first**

- Search: 'account linking OAuth email verified takeover' – understand the attack before coding

---

### OP-023 · Onboarding endpoint + incomplete-profile gate

**Week 2 · Core** · Spec p.2 'First sign-in runs a short onboarding flow… Required fields cannot be skipped'

First sign-in forces the short profile; nothing else works until it's done.

**API / interface**

`POST /api/v1/me/onboarding {founderName, startupName, stageId, sectorId, city, website?} → 200 · GET /api/v1/me shows onboarded:true`

**Acceptance criteria**

- [ ] All fields except website required (400 with field errors); stageId/sectorId must exist
- [ ] Sets `onboarded=true`; calling again → 409 (use profile edit instead)
- [ ] Gate: a `OncePerRequestFilter` or interceptor returns 403 `ONBOARDING_REQUIRED` for any authenticated founder request except /me, /me/onboarding, /auth/**, when `onboarded=false`
- [ ] Admins are never gated

**Tests**

- IT: new founder hits /grants → 403 ONBOARDING_REQUIRED; after onboarding → 200; second onboarding → 409; missing city → 400

**Read first**

- Spring: `OncePerRequestFilter`, `HandlerInterceptor` – pick and justify

---

### OP-024 · Profile view/edit + manage sign-in methods

**Week 2 · Core** · Spec p.2 'Profile page: view and edit the above, manage sign-in details'

A founder can see and change everything they entered, and manage how they log in.

**API / interface**

`GET /api/v1/me · PATCH /api/v1/me {any onboarding field} · PUT /api/v1/me/password {current, new} · DELETE /api/v1/me/identities/{provider}`

**Acceptance criteria**

- [ ] PATCH updates only provided fields (JSON merge semantics; explain how you distinguish 'absent' from 'null')
- [ ] Email is NOT editable here (would break identity); document as a deliberate decision
- [ ] Change password requires current password; invalidates refresh tokens
- [ ] Unlinking an identity is refused if it's the last way to log in (409)

**Tests**

- IT: PATCH one field leaves others intact; wrong current password 400; unlink last identity 409

**Read first**

- PATCH semantics: JSON Merge Patch (RFC 7386) – or `Optional`/`JsonNullable` in DTOs

---

### OP-025 · Stage/sector lookup tables, admin-editable

**Week 2 · Optional** · Spec p.2 'stage (dropdown, values set by T-Hub), sector (dropdown)'

Dropdown values are T-Hub's to set, not hard-coded enums.

**API / interface**

`GET /api/v1/lookups/stages · GET /api/v1/lookups/sectors (public) · POST/PUT/DELETE /api/v1/admin/lookups/{stages|sectors}`

**Acceptance criteria**

- [ ] `stage` and `sector` tables: id, name unique, sort_order, active
- [ ] Public endpoints return active only, ordered; admin can add/rename/deactivate (no hard delete once referenced – 409)
- [ ] Seed the initial values in a migration (`V<n>__seed_lookups.sql`)

**Tests**

- IT: deactivated stage disappears from public list but existing founders keep it; delete referenced → 409

---

### OP-026 · Security test suite

**Week 2 · Core**

Prove the security config does what you think it does. This is the most-asked-about code in interviews.

**Acceptance criteria**

- [ ] `TestAuth` helper mints tokens for founder / admin / unverified / not-onboarded founders
- [ ] Matrix test: each public endpoint 200 anonymous; each founder endpoint 401 anonymous, 200 founder; each admin endpoint 403 founder, 200 admin
- [ ] Expired access token → 401; tampered signature → 401; token with unknown founder id → 401
- [ ] CORS preflight from configured origin → allowed; from other origin → blocked

**Tests**

- This story IS the tests

**Read first**

- Spring Security testing: `@WithMockUser`, `SecurityMockMvcRequestPostProcessors.jwt()` – or your own token helper

---

## E5 Admin layer

### OP-027 · Admin sign-in (single shared account) + admin route protection

**Week 2 · Core** · Spec p.6 Admin layer 'V1 ships with a single admin role'

T-Hub's one admin login, and a wall around every /admin endpoint.

**API / interface**

`POST /api/v1/auth/login works for the admin too; all /api/v1/admin/** require role ADMIN`

**Acceptance criteria**

- [ ] Admin founder row seeded by migration with a BCrypt hash whose plaintext comes from env at build time (or a `CommandLineRunner` that creates it from `ADMIN_EMAIL/ADMIN_PASSWORD` if missing – defend your choice)
- [ ] `@EnableMethodSecurity`; admin controllers annotated `@PreAuthorize("hasRole('ADMIN')")` at class level AND `/api/v1/admin/**` matched in the filter chain (belt and braces – explain why both)
- [ ] Admin is exempt from onboarding gate
- [ ] Swagger 'Authorize' works with the admin token

**Tests**

- IT: founder token on any admin endpoint → 403; admin → 200; anonymous → 401

**Read first**

- Spring Security: method security, role prefix gotcha (`ROLE_`)

---

### OP-028 · Admin: partners CRUD

**Week 2 · Optional** · Spec p.6 'Partners and offers are entered in V1'

Partners are entered in V1 so T-Hub can load them before Benefits goes live in V2.

**API / interface**

`POST/GET/PUT/DELETE /api/v1/admin/partners · POST …/{id}/feature · …/unfeature`

**Acceptance criteria**

- [ ] Migration `partner`: id, name unique, logo_url, website, featured bool, sort_order, created/updated
- [ ] Validation: name required, logo_url/website valid URLs
- [ ] Delete refused (409) if the partner has offers

**Tests**

- IT: CRUD happy path; duplicate name 409; delete with offers 409

---

### OP-029 · Admin: offers CRUD with publish toggle + expiry

**Week 2 · Optional** · Spec p.7 Benefits 'Admin manages partners and offers'

Each partner's offers, ready for the V2 Benefits listing.

**API / interface**

`POST/GET/PUT/DELETE /api/v1/admin/offers · …/{id}/publish · …/unpublish`

**Acceptance criteria**

- [ ] Migration `offer`: id, partner_id FK, headline, category enum (CLOUD|DEV_TOOLS|BUSINESS_TOOLS|SERVICES), eligibility_note, what_you_get text, how_to_claim text, claim_url/claim_code nullable, valid_until date nullable, published bool
- [ ] Same publish/unpublish pattern as grants (reuse a `Publishable` interface or base class? decide and note)
- [ ] Admin list filterable by partner and published state

**Tests**

- IT: create under partner; publish; list by partner

---

## E3 Corporate Challenges

### OP-030 · Challenge entity + migration

**Week 2 · Core** · Spec p.4 Corporate Challenges

Model a corporate challenge including the optional detail section.

**Acceptance criteria**

- [ ] Migration `corporate_challenge`: id, corporate_name, corporate_logo_url, title, sector_id FK, theme, deadline date not null, status enum OPEN|CLOSED, apply_url, published bool, has_detail bool, problem_statement text null, looking_for text null, eligibility text null, timeline text null, offer_type enum PILOT|POC|PARTNERSHIP null, created/updated
- [ ] Indexes: published+status, deadline, sector_id
- [ ] `has_detail` is derived: true iff problem_statement is present (compute in service, store for query speed – or use a DB generated column; defend)

**Tests**

- Repository IT: save/load with and without detail

---

### OP-031 · Admin: challenges CRUD + publish/unpublish/close

**Week 2 · Core** · Spec p.4 'Admin creates, edits, publishes, unpublishes and closes challenges'

T-Hub adds and edits challenges from its corporate relationships.

**API / interface**

`POST/GET/PUT/DELETE /api/v1/admin/challenges · …/{id}/publish · …/unpublish · …/close`

**Acceptance criteria**

- [ ] Validation: corporate_name, title, sector, theme, deadline (today or future on create), apply_url required; detail fields all-or-nothing (if any of problem_statement/looking_for is set, both required)
- [ ] `close` sets status CLOSED manually; a closed challenge cannot be reopened via edit (409) – deadline change on an OPEN challenge is allowed
- [ ] Same publish semantics as grants

**Tests**

- IT: create with past deadline 400; partial detail 400; close then edit status 409

---

### OP-032 · Listing: filters, keyword, sort; closed stay visible but marked

**Week 2 · Core** · Spec p.4

The challenge discovery page.

**API / interface**

`GET /api/v1/challenges?sectorId=&theme=&corporate=&status=&q=&sort=newest|deadline&page=&size=`

**Acceptance criteria**

- [ ] Published only; CLOSED challenges included by default with `status: CLOSED` on the card (spec: browsable but marked)
- [ ] Filters: sectorId, theme (exact, from a distinct list – add GET /api/v1/challenges/themes), corporate (exact name), status
- [ ] `q` over title + problem_statement
- [ ] `sort=newest` (created_at desc, default) or `sort=deadline` (deadline asc); anything else 400
- [ ] Card DTO: id, corporateName, logoUrl, title, sector, theme, deadline, status, hasDetail
- [ ] Reuse the Specification approach from Grants – if you find yourself copy-pasting the page/sort plumbing, extract a small `ListingSupport` helper (but don't build a framework)

**Tests**

- IT: each filter; closed appear with status; q hits problem statement; both sorts; unpublished hidden

---

### OP-033 · Challenge detail (optional) + connect action

**Week 2 · Optional** · Spec p.4 'Challenges without a detail page show the card information and the connect action only'

Where a corporate supplied a detail page, show it; where not, the card is all there is.

**API / interface**

`GET /api/v1/challenges/{id} · GET /api/v1/challenges/{id}/apply → 302 to apply_url (or 200 {applyUrl})`

**Acceptance criteria**

- [ ] `has_detail=false` → detail endpoint returns the card fields + applyUrl only (200, not 404) with `hasDetail:false`
- [ ] `has_detail=true` → full detail: problemStatement, lookingFor, eligibility, timeline, deadline, offerType, applyUrl
- [ ] Apply endpoint records nothing (spec: no submission tracking) – it exists so the frontend has one place to get the link; document why you chose redirect vs JSON
- [ ] Closed challenge: detail still viewable; apply link still returned but `status: CLOSED`

**Tests**

- IT: with/without detail shapes; closed still 200

---

### OP-034 · Auto-close scheduler at deadline

**Week 2 · Core** · Spec p.4 'A challenge closes automatically when its deadline passes'

A challenge closes itself when its deadline passes – no admin action.

**Acceptance criteria**

- [ ] `ChallengeAutoCloseJob` runs on a cron (config) – set to hourly; sets status CLOSED where `deadline < today(IST)` and status OPEN
- [ ] Business date is IST: compute `LocalDate.now(clock.withZone(ASIA_KOLKATA))` – write down in the PR why 'today' is timezone-dependent
- [ ] `Clock` injected; job idempotent; logs count
- [ ] ShedLock (or a `SELECT … FOR UPDATE SKIP LOCKED` pattern) so two app instances don't both run it – explain the problem it solves even though we run one instance

**Tests**

- Unit: fixed Clock at 2026-10-01T00:30 IST closes deadline 2026-09-30, leaves 2026-10-01
- IT: job flips a row

**Read first**

- ShedLock README
- java.time: ZoneId, Clock

---

### OP-035 · Challenges: full test coverage to DoD

**Week 2 · Core**

Same bar as Grants.

**Acceptance criteria**

- [ ] Service unit tests for close/publish rules and detail all-or-nothing
- [ ] ITs for every endpoint and the job
- [ ] One deliberate break

**Tests**

- This story IS the tests

---

## E4 Mentors

### OP-036 · Mentor entity + expertise tags

**Week 2 · Core** · Spec p.3 Connect to People

Mentors with a many-to-many tag model that the multi-select filter can query efficiently.

**Acceptance criteria**

- [ ] Migration `mentor`: id, name, photo_url, headline (role + company), bio text, experience text, links jsonb or `mentor_link` table, calcom_url not null, stage_id null, sector_id null, status enum SEEDED|PENDING|APPROVED|REJECTED, published bool, created/updated
- [ ] `expertise_tag` (id, name unique) and `mentor_expertise` join table; index on mentor_expertise(tag_id)
- [ ] Seeded mentors are `status=APPROVED, published=true`

**Tests**

- Repository IT: mentor with 3 tags round-trips; tag lookup by name

---

### OP-037 · Seed loader from T-Hub CSV

**Week 2 · Optional** · Spec p.3 'V1: mentor records are loaded from the list T-Hub seeds'

Load the initial mentor list from a CSV the lead provides, repeatably.

**API / interface**

`CLI/profile-gated: `./mvnw spring-boot:run -Dspring-boot.run.arguments=--seed.mentors=path.csv` or an admin endpoint POST /api/v1/admin/mentors/import (multipart CSV)`

**Acceptance criteria**

- [ ] Columns: name, headline, bio, expertise (pipe-separated), calcom_url, photo_url, stage, sector
- [ ] Idempotent: re-running with the same file does not duplicate (match on name+calcom_url)
- [ ] Unknown tags are created; unknown stage/sector → row rejected with a reason
- [ ] Returns/logs a report: inserted, updated, rejected[{line, reason}]
- [ ] Use a CSV library (commons-csv / opencsv), not `split(",")`

**Tests**

- Unit: parser with a good row, a bad row, a quoted comma
- IT: import twice → same count

**Read first**

- Apache Commons CSV

---

### OP-038 · Mentor listing: expertise multi-select, stage, sector, keyword, pagination

**Week 2 · Core** · Spec p.3

The mentor discovery page.

**API / interface**

`GET /api/v1/mentors?expertise=pricing&expertise=fundraising&stageId=&sectorId=&q=&page=&size=`

**Acceptance criteria**

- [ ] `published=true AND status=APPROVED` only
- [ ] `expertise` repeatable param: mentor must have ANY of the given tags (document; ALL is a one-line change – say which the spec implies)
- [ ] stage/sector filters only apply when mentor has that data (null matches nothing when filter set)
- [ ] `q` over name, headline, tag names
- [ ] Card DTO: id, name, photoUrl, headline, expertise[]
- [ ] No duplicate rows from the tag join; no N+1 loading tags for a page of 20 (`@EntityGraph` or a second query) – show the SQL log in the PR

**Tests**

- IT: single tag; two tags OR; q on tag name; page of 20 issues ≤ 2 SELECTs (assert with a Hibernate statistics or datasource-proxy counter)

**Read first**

- Hibernate N+1: `@EntityGraph`, `@BatchSize`
- Search 'count queries in Spring Boot tests' (datasource-proxy / Hibernate Statistics)

---

### OP-039 · Mentor detail with cal.com link

**Week 2 · Core** · Spec p.3 'Booking runs on cal.com, not Outpost'

Everything the founder needs before clicking Book a call.

**API / interface**

`GET /api/v1/mentors/{id}`

**Acceptance criteria**

- [ ] Returns bio, expertise[], experience, links[], headline, photoUrl, `bookingUrl` (calcom_url)
- [ ] Unpublished / non-approved → 404
- [ ] Outpost stores nothing about bookings (spec) – say so in the OpenAPI description

**Tests**

- IT: approved → 200; pending → 404

---

### OP-040 · V2: public mentor application form → PENDING

**Week 3 · Core** · Spec p.3 'V2: mentors can apply through a short form'

Anyone can apply to be a mentor; applications wait for T-Hub.

**API / interface**

`POST /api/v1/mentors/apply {name, email, headline, bio, expertise[], calcomUrl, photoUrl?, linkedinUrl?} → 202`

**Acceptance criteria**

- [ ] Public (no auth); creates mentor with status PENDING, published=false; stores applicant email in `mentor_application` (mentor_id, email, submitted_at, decided_at, decided_by, reason)
- [ ] Validation: all required fields, calcomUrl must be a cal.com URL, expertise 1–5 tags
- [ ] Duplicate pending application for same email → 409
- [ ] Rate limit 5/hour per IP (simple in-memory bucket is fine; note what you'd use in prod)

**Tests**

- IT: apply → PENDING invisible in listing; duplicate 409; invalid calcom URL 400

---

### OP-041 · V2: admin approval queue + edit/remove live mentors

**Week 3 · Core** · Spec p.6 'V2: mentor approval queue (pending, approved, rejected)'

A state machine: PENDING → APPROVED | REJECTED, and admin control over the live list.

**API / interface**

`GET /api/v1/admin/mentors?status=PENDING · POST /api/v1/admin/mentors/{id}/approve · POST …/reject {reason} · PUT /api/v1/admin/mentors/{id} · DELETE /api/v1/admin/mentors/{id}`

**Acceptance criteria**

- [ ] Transitions enforced in the service (`MentorStatus.canTransitionTo`): PENDING→APPROVED, PENDING→REJECTED only; anything else 409 `INVALID_TRANSITION`
- [ ] Approve sets status APPROVED + published=true + decided_at/by; reject records reason; both idempotent-safe (approving an APPROVED → 409, not silent)
- [ ] Applicant gets an email on decision (FakeEmailSender in tests)
- [ ] DELETE = unpublish + soft-delete flag (never lose the row; explain soft delete trade-offs in PR)
- [ ] Queue list sorted oldest first

**Tests**

- Unit: every transition in a parameterised test
- IT: approve → appears in public listing; reject → email captured; approve twice 409

**Read first**

- State machine pattern (enum with transition method) – no library needed

---

### OP-042 · Mentors: full test coverage to DoD

**Week 2 · Core**

Same bar as Grants.

**Acceptance criteria**

- [ ] Unit + IT for listing, detail, seed, and later the queue
- [ ] N+1 assertion kept green
- [ ] One deliberate break

**Tests**

- This story IS the tests

---

## E10 AI layer

### OP-043 · LlmClient abstraction + one provider + fake

**Week 3 · Core** · Spec p.2–3 'Integrated AI'

One interface the whole platform uses to talk to an LLM; the provider is a detail.

**API / interface**

`internal: `interface LlmClient { RankResult rank(RankRequest r); }``

**Acceptance criteria**

- [ ] `LlmClient` in `ai/` with a `RankRequest` (founder profile summary, candidate items [{id, text}], instruction) and `RankResult` (ordered ids with a one-line reason each)
- [ ] One real implementation using `RestClient` against the provider the lead chose (key from `LLM_API_KEY`), asking for JSON output and parsing it strictly (reject anything that isn't the expected shape)
- [ ] `FakeLlmClient` (returns items in reverse order with canned reasons) wired under the `test` profile and when `LLM_API_KEY` is empty
- [ ] Prompt is a text resource file, not a string concatenated in Java; candidate text is truncated to a max length
- [ ] Never send PII beyond what ranking needs (name of startup ok; email no) – list what you send in the PR

**Tests**

- Unit: JSON parsing of a good and a malformed provider response
- Contract test (manual/`@Tag("external")`, skipped in CI) that hits the real provider once

**Read first**

- Spring `RestClient`
- Your provider's API docs: structured/JSON output
- OWASP LLM top 10 (prompt injection – you are sending user-authored text)

---

### OP-044 · Resilience: timeouts, retry, circuit breaker, fallback to keyword

**Week 3 · Core**

The AI never takes the site down. If it's slow or broken, founders get normal search.

**Acceptance criteria**

- [ ] Connect timeout 2s, read timeout 8s on the provider call
- [ ] Resilience4j: retry (2 attempts, exponential backoff, only on 5xx/timeouts – never on 4xx), circuit breaker (opens after 50% failures over 10 calls, half-open after 30s)
- [ ] Fallback: any failure → the listing returns the keyword/filter results unchanged with `aiApplied:false` in the response; never a 500 to the founder
- [ ] Actuator exposes circuit breaker state (`/actuator/circuitbreakers`)
- [ ] Log every fallback at WARN with the cause

**Tests**

- Unit with a stub client that throws: retry count observed; breaker opens after N failures; fallback returns keyword results
- IT: kill the fake → listing still 200 with aiApplied:false

**Read first**

- Resilience4j Spring Boot 3 docs
- Release It! chapter summaries on circuit breaker (any blog)

---

### OP-045 · AI search for Mentors

**Week 3 · Core** · Spec p.3 'AI search results to show relevant mentors based on the founder's profile'

'Show me mentors for my situation' – ranked by the founder's profile.

**API / interface**

`GET /api/v1/mentors?ai=true&q=… (same endpoint, one flag) → adds `aiApplied`, and per card `aiReason``

**Acceptance criteria**

- [ ] When `ai=true`: run the normal filters/q first, take the top 30 candidates, send profile summary (stage, sector, city, startup name, q) + candidate text (headline + tags + first 200 chars of bio) to `LlmClient.rank`, return in the ranked order with reasons
- [ ] Pagination applies AFTER ranking (rank once per request; page from the ranked list) – explain the trade-off
- [ ] Founder without onboarding can't hit this (gate already blocks)
- [ ] Latency of the AI call logged; p95 target < 3s locally with the real provider

**Tests**

- IT with FakeLlmClient: order is the fake's order; reasons present; ai=false unchanged

---

### OP-046 · AI search for Challenges + Grants

**Week 3 · Core** · Spec p.4–5

Same abstraction, two more listings. If this takes more than a few hours, OP-045 wasn't generic enough – fix that instead of copying.

**API / interface**

`GET /api/v1/challenges?ai=true · GET /api/v1/grants?ai=true`

**Acceptance criteria**

- [ ] A single `AiRankingService.rank(profile, items, textExtractor)` used by all three listings
- [ ] Candidate text: challenges = title + theme + problem statement snippet; grants = name + summary + eligibility snippet
- [ ] Same fallback + `aiApplied` contract

**Tests**

- IT per listing with the fake

---

### OP-047 · Cache AI results + rate limit per founder

**Week 3 · Optional**

Control cost and latency: identical asks don't hit the provider twice; nobody can hammer it.

**Acceptance criteria**

- [ ] Spring Cache (`@Cacheable`) with Caffeine: key = hash(founderId profile fields + listing + filters + q), TTL 1h, max 10k entries
- [ ] Cache is bypassed when the fake client is active (tests stay deterministic) – or test the cache explicitly
- [ ] Rate limit: 30 AI requests per founder per hour (Bucket4j or a simple DB/Caffeine counter); over → 429 with `Retry-After`
- [ ] Actuator cache metrics visible

**Tests**

- Unit: same request twice → provider called once
- IT: 31st request → 429

**Read first**

- Spring Cache abstraction, Caffeine
- Bucket4j

---

### OP-048 · AI feature flag per module (admin toggle)

**Week 3 · Optional**

T-Hub can switch AI off for a module without a deploy.

**API / interface**

`GET/PUT /api/v1/admin/settings/ai {mentors:true, challenges:false, grants:true}`

**Acceptance criteria**

- [ ] `app_setting` table (key, value jsonb) with a small `SettingsService` (cached, refreshed on write)
- [ ] When off, `ai=true` is ignored: `aiApplied:false`, no provider call
- [ ] Defaults on if row absent

**Tests**

- IT: toggle off → fake not called

---

### OP-049 · AI layer: tests to DoD

**Week 3 · Core**

Everything above tested without ever calling a real provider in CI.

**Acceptance criteria**

- [ ] Fake used in all ITs; contract test tagged external and excluded from `verify`
- [ ] Resilience unit tests green
- [ ] One deliberate break

**Tests**

- This story IS the tests

**Read first**

- Maven Surefire: excluding tags

---

## E6 Enriched profile

### OP-050 · profile_attachments model (extensible)

**Week 3 · Core** · Spec p.2 'Data model built so future modules can attach records… without migrating the spine'

Future modules attach records to the founder without touching the spine – design that now.

**Acceptance criteria**

- [ ] Migration `founder_profile` (founder_id PK/FK, bio text null, links jsonb null, visibility enum PRIVATE|THUB|PUBLIC default THUB, updated_at) – separate table, 1:1
- [ ] Migration `founder_attachment` (id, founder_id, kind enum PITCH_DECK|OTHER, storage_key, file_name, content_type, size_bytes, uploaded_at) – 1:N, one PITCH_DECK max enforced in service
- [ ] Write a short ADR in `docs/adr/0001-profile-extension.md`: why separate tables, what a future 'applications' or 'check-ins' table would look like

**Tests**

- Repository IT: founder with profile + attachment loads; deleting founder cascades (decide and test)

**Read first**

- ADR format (Michael Nygard)

---

### OP-051 · StorageService: local + S3-compatible (MinIO)

**Week 3 · Core**

File storage behind an interface; MinIO locally, real S3 in prod, nothing in the DB.

**API / interface**

`internal: `interface StorageService { String put(key, InputStream, contentType, size); Resource get(key); void delete(key); URL presignedGet(key, ttl); }``

**Acceptance criteria**

- [ ] `S3StorageService` using AWS SDK v2 against `S3_ENDPOINT` (MinIO) with path-style access; bucket created on startup if missing (local profile only)
- [ ] `LocalFsStorageService` under `test` profile (temp dir) so ITs don't need MinIO
- [ ] Keys are `founders/{founderId}/pitch-deck/{uuid}.pdf` – never the original filename
- [ ] Presigned GET URLs (10 min) for downloads – the app never streams big files through itself

**Tests**

- Unit: key generation
- IT (local fs): put → get → delete

**Read first**

- AWS SDK v2 S3Client + presigner; MinIO path-style note

---

### OP-052 · Pitch deck upload / replace / remove with validation

**Week 3 · Core** · Spec p.2 'Pitch deck upload: PDF, size limit set during build, founder can replace or remove it'

A founder can attach one PDF pitch deck to their profile.

**API / interface**

`PUT /api/v1/me/pitch-deck (multipart, field `file`) → 200 {fileName, sizeBytes, uploadedAt} · GET /api/v1/me/pitch-deck → 302 presigned URL · DELETE /api/v1/me/pitch-deck → 204`

**Acceptance criteria**

- [ ] Max size from config (`outpost.uploads.pitch-deck.max-bytes`, default 10 MB) → 413 over; `spring.servlet.multipart.max-file-size` aligned
- [ ] Type check by magic bytes (`%PDF-`), not extension or client content-type → 415 otherwise
- [ ] PUT replaces: old object deleted from storage after the new one is stored (order matters – say why)
- [ ] Upload streamed to storage, not buffered fully in memory (`MultipartFile.getInputStream()`)
- [ ] Admin can GET any founder's deck: GET /api/v1/admin/founders/{id}/pitch-deck

**Tests**

- IT: upload valid PDF → 200; 11 MB → 413; a .pdf that is actually PNG → 415; replace leaves exactly one attachment; delete → 404 on next GET

**Read first**

- Spring: multipart config
- Search 'magic bytes file type validation java'

---

### OP-053 · Bio + links

**Week 3 · Optional** · Spec p.2 'Free-text bio. Links: LinkedIn, X, and any other URL'

Free-text bio and a list of links on the enriched profile.

**API / interface**

`PATCH /api/v1/me/profile {bio?, links?:[{type: LINKEDIN|X|OTHER, url}]}`

**Acceptance criteria**

- [ ] bio ≤ 2000 chars; links ≤ 5, each a valid https URL; LINKEDIN/X types validated against their domains
- [ ] Stored on `founder_profile` (links as jsonb – show the JPA mapping)
- [ ] Included in GET /me under `profile`

**Tests**

- IT: PATCH bio only leaves links; 6 links → 400; http:// link → 400

**Read first**

- Hibernate 6 JSON mapping (`@JdbcTypeCode(SqlTypes.JSON)`)

---

### OP-054 · Visibility rule (founder, admin, Founder of the Day)

**Week 3 · Optional** · Spec p.2 'Default assumption: visible to the founder and to T-Hub through admin, and used by Founder of the Day'

Who can see an enriched profile, per the spec's default assumption.

**API / interface**

`GET /api/v1/founders/{id}/profile`

**Acceptance criteria**

- [ ] Default visibility THUB: the founder themself and admins can read; other founders get 404 (not 403 – don't reveal existence)
- [ ] If the founder is the current Founder of the Day (OP-067), their profile (bio, links, startup – NOT pitch deck) is readable by any signed-in founder
- [ ] Founder can set visibility PRIVATE (only self + admin) – PUBLIC reserved, returns 400 for now

**Tests**

- IT: other founder 404; admin 200; spotlighted founder → 200 for others, no pitch deck field

---

### OP-055 · Enriched profile: tests to DoD

**Week 3 · Core**

Same bar.

**Acceptance criteria**

- [ ] Unit + IT for storage, upload paths, visibility
- [ ] One deliberate break

**Tests**

- This story IS the tests

---

## E7 Benefits

### OP-056 · Benefits listing: featured partners, filters, keyword, expired hidden

**Week 3 · Optional** · Spec p.7 Benefits

The credits & tools page.

**API / interface**

`GET /api/v1/benefits?category=&partnerId=&q=&includeExpired=&page=&size= · GET /api/v1/benefits/featured`

**Acceptance criteria**

- [ ] Published offers whose partner exists; `valid_until < today` hidden unless includeExpired
- [ ] `/featured` returns partners with `featured=true` and their published offer count, ordered by sort_order
- [ ] Filters category, partnerId; `q` over partner name + headline
- [ ] Card: id, partner{name, logoUrl}, headline, category, eligibilityNote, validUntil
- [ ] A partner with several offers appears once in `/featured`, and each offer once in the list (spec)

**Tests**

- IT: expired hidden; featured ordering; q on partner name

---

### OP-057 · Offer detail: what you get, eligibility, how to claim, validity

**Week 3 · Optional** · Spec p.7 'Offer detail page'

Everything needed to claim, on the partner's side.

**API / interface**

`GET /api/v1/benefits/{id}`

**Acceptance criteria**

- [ ] Returns whatYouGet, eligibility, howToClaim (steps text), claimUrl/claimCode, validUntil, partner block
- [ ] Unpublished → 404; expired → 200 with expired:true

**Tests**

- IT shapes

---

### OP-058 · AI recommendations for benefits

**Week 3 · Optional** · Spec p.7

Fourth use of the ranking service.

**API / interface**

`GET /api/v1/benefits?ai=true`

**Acceptance criteria**

- [ ] Candidate text = partner name + headline + eligibility note
- [ ] Same aiApplied/fallback contract

**Tests**

- IT with fake

---

### OP-059 · Benefits: tests to DoD

**Week 3 · Optional**

Same bar.

**Acceptance criteria**

- [ ] ITs for listing/featured/detail
- [ ] One deliberate break

**Tests**

- This story IS the tests

---

## E8 Hiring / Talent pool

### OP-060 · Candidate entity + migration

**Week 3 · Optional** · Spec p.8 Hiring / Talent pool

Model T-Hub's talent pool.

**Acceptance criteria**

- [ ] Migration `candidate`: id, name, email, phone null, role_sought, experience_level enum (INTERN|JUNIOR|MID|SENIOR), location, availability enum (IMMEDIATE|NOTICE_PERIOD|OPEN_TO_OFFERS), summary text, resume_storage_key null, published bool, created/updated; `skill` (id, name unique) + `candidate_skill`
- [ ] Contact fields are PII – add a note in the PR on where they are exposed (only to signed-in founders) and logged (never)

**Tests**

- Repository IT

---

### OP-061 · CSV bulk import (validation, partial failure report, idempotent)

**Week 3 · Optional** · Spec p.8 'loaded by import during the build'

Load T-Hub's pool from a file, safely, more than once.

**API / interface**

`POST /api/v1/admin/candidates/import (multipart CSV) → 200 {inserted, updated, rejected:[{line, reason}]}`

**Acceptance criteria**

- [ ] Same parser approach as OP-037; match on email for idempotency
- [ ] One bad row does not abort the file; each row's outcome is reported
- [ ] Batch inserts (`saveAll` with `hibernate.jdbc.batch_size` set, or JdbcTemplate batch) – import 5k rows locally and note the time
- [ ] Skills auto-created

**Tests**

- Unit: parser edge cases
- IT: import twice → no duplicates; bad row reported

**Read first**

- Hibernate batch inserts (Vlad Mihalcea)

---

### OP-062 · Candidate directory (signed-in only): filters, keyword, pagination

**Week 3 · Optional** · Spec p.8 'visible only to signed-in founders'

Founders browse candidates.

**API / interface**

`GET /api/v1/candidates?role=&skill=&experience=&location=&availability=&q=&page=&size=`

**Acceptance criteria**

- [ ] Requires an onboarded founder (already enforced) – add a test proving anonymous gets 401
- [ ] Filters as listed; `skill` repeatable (ANY); `q` over name, role, skills
- [ ] Card excludes contact details (those are on the resume page)

**Tests**

- IT: filters; anonymous 401; card has no email

---

### OP-063 · Candidate resume page + admin add/edit form

**Week 3 · Optional** · Spec p.8

Full candidate view for founders; manual maintenance for admin.

**API / interface**

`GET /api/v1/candidates/{id} (incl. contact + presigned resume URL) · POST/PUT/DELETE /api/v1/admin/candidates · PUT /api/v1/admin/candidates/{id}/resume (multipart PDF)`

**Acceptance criteria**

- [ ] Resume upload reuses StorageService + PDF validation from OP-052 (extract a `PdfUploadValidator` if you copy code)
- [ ] Detail includes email/phone – log an INFO 'candidate viewed' event with founderId + candidateId (audit, no PII)

**Tests**

- IT: detail has contact; admin CRUD

---

### OP-064 · Smart recommendations from founder profile

**Week 3 · Optional** · Spec p.8 'Smart recommendations based on founder's profile'

Fifth use of the ranking service.

**API / interface**

`GET /api/v1/candidates?ai=true`

**Acceptance criteria**

- [ ] Candidate text = role + skills + summary; profile adds startup name + sector
- [ ] Same contract

**Tests**

- IT with fake

---

### OP-065 · Hiring: tests to DoD

**Week 3 · Optional**

Same bar.

**Acceptance criteria**

- [ ] ITs for all endpoints, import, PII exposure rules
- [ ] One deliberate break

**Tests**

- This story IS the tests

---

## E9 Founder of the Day

### OP-066 · Spotlight schedule: admin pick + upcoming queue

**Week 3 · Core** · Spec p.6 'Founder of the Day scheduler'

T-Hub decides who's featured and when.

**API / interface**

`POST /api/v1/admin/spotlight {founderId, date} → 201 · GET /api/v1/admin/spotlight?from=today → upcoming · DELETE /api/v1/admin/spotlight/{id} · GET /api/v1/admin/founders?q= (to pick from)`

**Acceptance criteria**

- [ ] Migration `spotlight_schedule` (id, founder_id, spotlight_date unique, one_liner text, created_by)
- [ ] Date must be today or future (IST); one founder per date (409 on clash); a founder may be scheduled multiple times
- [ ] Only onboarded founders can be scheduled (400 otherwise)

**Tests**

- IT: schedule; clash 409; past date 400; upcoming sorted

---

### OP-067 · Homepage spotlight endpoint: today's founder (IST) with fallback

**Week 3 · Core** · Spec p.9 'The slot switches automatically at the start of each day (IST)… If no founder is scheduled for a day, the most recent one stays up'

The homepage slot, correct at midnight IST, never empty once someone has been featured.

**API / interface**

`GET /api/v1/spotlight (signed-in) → {founder:{name, startupName, photoUrl?, oneLiner}, date, profileUrl}`

**Acceptance criteria**

- [ ] 'Today' = `LocalDate.now(clock.withZone(Asia/Kolkata))`; returns the schedule for today if present
- [ ] If none for today → the most recent past schedule (spec: 'the most recent one stays up'); if none at all → 204
- [ ] No scheduler needed – resolve on read (explain why this is better than a midnight job here)
- [ ] Response cached for 60s (`@Cacheable` with TTL or HTTP `Cache-Control`)

**Tests**

- Unit with fixed Clock: 23:59 IST vs 00:01 IST pick different founders; fallback to most recent; 204 when empty

---

### OP-068 · Founder of the Day: tests to DoD

**Week 3 · Core**

Same bar.

**Acceptance criteria**

- [ ] Clock-driven unit tests + ITs
- [ ] One deliberate break

**Tests**

- This story IS the tests

---

## E11 Production

### OP-069 · Correlation ID filter + JSON structured logging

**Week 4 · Core**

Every log line for a request can be found with one id; logs are machine-readable in prod.

**API / interface**

`Response header `X-Request-Id` on every response`

**Acceptance criteria**

- [ ] `OncePerRequestFilter` first in chain: read `X-Request-Id` or generate UUID, put in MDC (`requestId`, plus `founderId` once authenticated), clear after
- [ ] Logback JSON encoder (logstash-logback-encoder) under `prod` profile; human-readable pattern with requestId under `local`
- [ ] ProblemDetail `instance` carries the request id so a founder can quote it
- [ ] No PII (emails, tokens) in logs – grep your codebase for `log.*email`

**Tests**

- IT: response has X-Request-Id; provided id is echoed; error body instance contains it

**Read first**

- Logback MDC
- logstash-logback-encoder README

---

### OP-070 · Actuator secured + custom health + Micrometer metrics

**Week 4 · Core**

Operators can see if it's alive and how it's doing; nobody else can.

**API / interface**

`GET /actuator/health (public, minimal) · GET /actuator/health/detailed, /metrics, /prometheus, /circuitbreakers (ADMIN or a separate management token)`

**Acceptance criteria**

- [ ] Custom `HealthIndicator`s: database (built-in), object storage (HEAD bucket), LLM provider (last call status, no live call)
- [ ] Micrometer timers: `outpost.listing.query` tagged by module; `outpost.ai.rank` tagged by module and outcome; counters for fallbacks and 429s
- [ ] Prometheus endpoint enabled; management port or path documented
- [ ] Actuator endpoints other than health require ADMIN

**Tests**

- IT: health public 200 without details; /metrics anonymous 401; admin 200; custom indicators present

**Read first**

- Spring Boot Actuator: health groups, exposure, security
- Micrometer basics

---

### OP-071 · Load test listings; fix slowest query; pool tuning

**Week 4 · Optional**

Measure before you tune, then tune one thing and prove it.

**Acceptance criteria**

- [ ] k6 script hitting /grants, /mentors, /challenges with mixed filters at 50 VUs for 2 min; record p50/p95 and error rate in `docs/perf.md`
- [ ] Enable slow-query logging (`log_min_duration_statement=200ms`) and Hibernate statistics; identify the slowest query; fix it (index, fetch strategy, projection) and record before/after
- [ ] HikariCP: set `maximumPoolSize` deliberately (rule of thumb from the HikariCP wiki) and document

**Tests**

- The perf doc is the deliverable; existing tests stay green

**Read first**

- k6 quick start
- HikariCP 'About pool sizing' wiki page
- Postgres `EXPLAIN (ANALYZE, BUFFERS)`

---

### OP-072 · Multi-stage Dockerfile + full docker-compose

**Week 4 · Core**

The app runs as a container the same way everywhere.

**API / interface**

``docker compose --profile full up` starts app + postgres + minio + mailpit`

**Acceptance criteria**

- [ ] Multi-stage Dockerfile: build stage with Maven cache layer, run stage on a slim JRE 21 image, non-root user, layered jar (`spring-boot:build-image` or `layertools`) for cache-friendly rebuilds
- [ ] `JAVA_TOOL_OPTIONS=-XX:MaxRAMPercentage=75` and the reason in a comment
- [ ] Health check in the image; app container waits for postgres healthy
- [ ] Image size recorded in the PR; secrets via env, none baked in

**Tests**

- `docker build` succeeds in CI (added as a job); container answers /actuator/health

**Read first**

- Spring Boot: Container images (layered jars)
- JVM in containers: MaxRAMPercentage

---

### OP-073 · CI/CD: PR build+test; main → image → deploy

**Week 4 · Core**

Merging to main ships to the environment, automatically.

**Acceptance criteria**

- [ ] Pipeline: PR → build+test; main → build+test → build image → push to registry (GHCR) → deploy to the target from OP-074
- [ ] Secrets in GitHub Actions secrets; DB migrations run by the app on startup (Flyway) – document the failure mode (bad migration = failed deploy = previous version keeps running?) and whether your platform gives you that
- [ ] Deployment step is idempotent and re-runnable; a badge in the README

**Tests**

- A merge to main produces a new running version, visible in the platform's dashboard

**Read first**

- GitHub Actions: docker/build-push-action, environments & secrets

---

### OP-074 · Deploy to cloud with managed Postgres + object storage

**Week 4 · Core**

Outpost on a public URL with real infrastructure.

**API / interface**

`https://outpost-<name>.<platform>… /actuator/health → UP`

**Acceptance criteria**

- [ ] Platform per lead's choice; managed Postgres; S3-compatible bucket (platform's or AWS S3); Mailpit replaced by a real SMTP provider sandbox or left as log-only sender under prod (`LogEmailSender`) – say which
- [ ] All config via env; `prod` profile; JWT secret, LLM key, S3 keys, DB URL set in the platform, not in git
- [ ] HTTPS terminated by the platform; CORS set to the (future) frontend origin
- [ ] Flyway migrations applied on first boot; admin account created; Swagger UI reachable (decide if it should be in prod – defend)

**Tests**

- Post-deploy: signup → verify (via logs or sandbox) → login → onboarding → /grants works end to end on the public URL

**Read first**

- Your platform's docs: env vars, Postgres add-on, custom start command

---

### OP-075 · Post-deploy smoke test

**Week 4 · Optional**

The pipeline knows whether the deploy actually works.

**Acceptance criteria**

- [ ] A pipeline step after deploy hits /actuator/health, /v3/api-docs, and /api/v1/grants with a smoke founder token (or anonymous 401 check); fails the workflow on non-2xx
- [ ] Runs against the real URL with a 60s wait/retry for startup

**Tests**

- The step itself

---

### OP-076 · README, architecture doc (5 ADRs), handover runbook

**Week 4 · Core**

Someone who has never seen this repo can run it, deploy it, and extend it.

**Acceptance criteria**

- [ ] README: what it is (link WHAT-IS-OUTPOST), how to run locally, how to run tests, env var table, how to deploy
- [ ] `docs/adr/`: at least 5 ADRs – e.g. JWT vs session, package-by-feature, Specifications for filtering, resolve-on-read spotlight, storage abstraction – each with context/decision/consequences
- [ ] `docs/RUNBOOK.md`: seed data, rotate JWT secret, add an admin, add a new listing module (step list), where logs/metrics are
- [ ] Architecture diagram (Mermaid) of request flow through filters → controller → service → repo/LLM/storage

**Tests**

- Reviewer follows the README on a clean clone and gets to a green build without asking you anything

**Read first**

- ADR examples (adr.github.io)

---

### OP-077 · OpenAPI complete + reviewed

**Week 4 · Optional**

The spec a frontend team could build against.

**API / interface**

`GET /v3/api-docs`

**Acceptance criteria**

- [ ] Every endpoint has summary, description, response codes incl. 4xx with ProblemDetail schema, and example values
- [ ] DTOs have field descriptions and constraints visible
- [ ] Generated spec committed as `docs/openapi.json` (CI regenerates and fails if drifted – optional)

**Tests**

- Diff check in CI or a manual review by a teammate acting as 'frontend dev'

**Read first**

- springdoc: `@Operation`, `@ApiResponse`, `@Schema`

---

### OP-078 · Final demo prep + presentation

**Week 4 · Core**

A 15-minute walkthrough you can give to a client tomorrow.

**Acceptance criteria**

- [ ] Script: 2 min what Outpost is → 3 min architecture (diagram) → 7 min live demo on the public URL (signup → onboarding → AI mentor search → admin publishes a grant → it appears) → 3 min one hard decision and what you'd do differently
- [ ] Seed data loaded so the demo isn't empty
- [ ] Dry-run once to a teammate
- [ ] Slides optional; the code and the running system are the presentation

**Tests**

- The demo

---
