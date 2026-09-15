#!/usr/bin/env bash
# Quick sanity check that your machine is ready. Run: ./scripts/check-env.sh
ok(){ printf "  \033[32m✔\033[0m %s\n" "$1"; }
bad(){ printf "  \033[31m✘\033[0m %s\n" "$1"; }

echo "Checking environment..."
if java -version 2>&1 | grep -q '"21'; then ok "Java 21"; else bad "Java 21 not found (java -version)"; fi
if command -v docker >/dev/null && docker info >/dev/null 2>&1; then ok "Docker running"; else bad "Docker not running"; fi
if command -v git >/dev/null; then ok "git"; else bad "git missing"; fi
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q outpost-postgres; then ok "Postgres container up"; else bad "Postgres not up – run: docker compose up -d"; fi
if [ -f pom.xml ]; then ok "Spring Boot project exists"; else bad "No pom.xml yet – create the project (README step 3)"; fi
