# Outpost – Starter

Your own copy of the Outpost backend starts here. This repo gives you the **infrastructure** (database, object storage, mail catcher, CI, PR template, Definition of Done). **You build everything else.**

Start here: [`docs/WHAT-IS-OUTPOST.md`](docs/WHAT-IS-OUTPOST.md) – the product on one page (sitemap, listing pattern, data model).
Spec: [`docs/Outpost-Prod-Spec.pdf`](docs/Outpost-Prod-Spec.pdf) – the single source of truth. If it's not in there, it's not in scope.
Rules: [`docs/DEFINITION_OF_DONE.md`](docs/DEFINITION_OF_DONE.md)

## Stack (fixed – don't debate, build)

| | |
|---|---|
| Language | Java 21 |
| Framework | Spring Boot 3.x (latest stable) |
| Build | Maven (wrapper) |
| Database | PostgreSQL 16 · Flyway migrations |
| Auth | Spring Security 6 · JWT · OAuth2 (Google, LinkedIn) |
| Tests | JUnit 5 · Mockito · MockMvc · Testcontainers |
| Docs | springdoc-openapi (Swagger UI) |
| Storage | MinIO (S3-compatible) for uploads |
| Mail | Mailpit in dev |
| CI | GitHub Actions (`.github/workflows/ci.yml`) |

## Day 1 – getting to a green build

### 1. Check your machine
```bash
./scripts/check-env.sh
```
Needs Java 21, Docker Desktop running, git.

### 2. Start infrastructure
```bash
docker compose up -d
```
- Postgres → `localhost:5432` (db/user/pass: `outpost`)
- MinIO console → http://localhost:9001 (`outpost` / `outpost123`)
- Mailpit → http://localhost:8025

### 3. Create the Spring Boot project – **in this repo root**
Go to https://start.spring.io and use exactly:

- Project: **Maven** · Language: **Java** · Spring Boot: **latest stable 3.x**
- Group: `com.thub` · Artifact: `outpost` · Package: `com.thub.outpost` · Java: **21** · Packaging: Jar
- Dependencies: `Spring Web`, `Spring Data JPA`, `Validation`, `Spring Security`, `OAuth2 Client`, `PostgreSQL Driver`, `Flyway Migration`, `Spring Boot Actuator`, `Testcontainers`, `Lombok` (optional)

Generate, unzip, and copy the contents into **this folder** so `pom.xml` sits next to this README. Commit the Maven wrapper (`mvnw`, `.mvn/`).

Then add manually to `pom.xml`: `org.springdoc:springdoc-openapi-starter-webmvc-ui`.

### 4. Make it run
- Configure `src/main/resources/application.yml` for the datasource above (use env vars, see `.env.example`).
- Add `src/main/resources/db/migration/V1__baseline.sql` (even an empty comment is fine to start).
- `./mvnw spring-boot:run` → http://localhost:8080/actuator/health returns `{"status":"UP"}`.
- Swagger UI at http://localhost:8080/swagger-ui.html.

### 5. Make CI green
Open a PR. CI runs `./mvnw verify` on Ubuntu with Docker, so Testcontainers tests work there. Your first PR is the skeleton (story **OP-003**). Once CI is green, you're on the tracker.

## How we work
- **One story per PR**, branch `OP-xxx-short-slug`. Fill the PR template – including the **AI used for / verified by** line.
- **Own repo, own code.** Nobody else commits here. You review a teammate's PR daily; they review yours.
- **Docs → tutorials → ask.** Stuck 20 minutes with real effort → ask the lead, starting with "here's what I tried".
- **AI is allowed everywhere.** Code you can't explain is not. Every demo ends with a live change, AI closed.
- **No secrets in git.** `.env` is ignored; keys come from the lead.

## Suggested package layout (package-by-feature)
```
com.thub.outpost
├── common/        errors, security, config, shared infrastructure
├── founder/       member spine: auth, onboarding, profile
├── grant/
├── challenge/
├── mentor/
├── partner/       partners + offers (benefits)
├── candidate/     hiring / talent pool
├── spotlight/     founder of the day
├── ai/            LLM client, recommendation services
└── admin/         admin-only endpoints (or keep admin endpoints inside each feature – your call, defend it)
```
Each feature owns its `controller / service / repository / entity / dto`. Features talk through services, never through each other's repositories.
