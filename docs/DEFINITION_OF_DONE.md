# Definition of Done

A story is **Done** only when all of these are true. No exceptions, no "will add tests later".

1. **Migration** – schema changes are in a Flyway migration (`V<n>__<description>.sql`). Never `ddl-auto=update`.
2. **Unit tests** – service logic has unit tests (JUnit 5 + Mockito).
3. **Integration test** – every new or changed endpoint has a MockMvc test against a real Postgres (Testcontainers), including at least one failure case (validation / 404 / 403).
4. **Tests bite** – you broke one test on purpose, watched it go red, and restored it.
5. **OpenAPI** – endpoint is documented and visible in Swagger UI.
6. **Reviewed** – one teammate (cross-repo) and the lead approved the PR.
7. **AI declared** – the PR says what AI was used for and how you verified it.
8. **Explained** – you walked through the code in demo and made the lead's live change with AI closed.
9. **Tracked** – your column on the Project Tracker says Done.

## Conventions
- Branch: `OP-012-grants-keyword-search` (story id + short slug)
- Commit: `OP-012: add keyword search to grants listing`
- One story per PR. Small PRs get reviewed; big ones wait.
