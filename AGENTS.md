# Repository Guidelines

This repo is a small Docker Compose environment for learning Apache NiFi with NiFi Registry, Postgres, Kafka, and Kafka UI.

## Project Structure & Module Organization

- `docker-compose.yml`: single entrypoint defining all services and ports.
- `drivers/`: JDBC drivers mounted into the NiFi container (e.g. `drivers/postgresql-42.7.4.jar`).
- `nifi-templates/`: NiFi templates/flows and helper SQL (`*.json`, `*.xml`, `*.sql`) mounted into Postgres at `/nifi-templates`.
- `README.md`: usage notes, URLs, and connection strings.
- (local) `shared-folder/`: host folder mounted to `/opt/nifi/nifi-current/ls-target` for file-based demos.

## Build, Test, and Development Commands

- `docker compose up`: start the full stack.
- `docker compose stop`: stop containers without removing volumes.
- `docker compose start`: start previously stopped containers (preserves all state).
- `docker compose down`: remove containers and networks.
- `docker compose down -v`: remove containers, networks, and all named volumes (destructive clean reset).
- `docker compose logs -f nifi`: follow NiFi logs while debugging processors.
- `docker compose exec postgres bash -c "export PGPASSWORD=postgres; psql -U postgres -d app"`: open `psql` in the Postgres container.

Notes on state persistence:
- `postgres`, `nifi`, and `registry` persist state via named volumes in `docker-compose.yml` (survive `docker compose down`, wiped by `docker compose down -v`).
- Kafka message/topic persistence is disabled by default (see the commented `kafka-data` volume in `docker-compose.yml`).

## Coding Style & Naming Conventions

- YAML: 2-space indentation; keep service names stable (`nifi`, `registry`, `postgres`, `kafka`, `kafka-ui`) to avoid breaking docs.
- Templates: name files by purpose and target, e.g. `SampleKafka2Postgres.json` and matching `SampleKafka2Postgres.sql`.
- Docs: keep `README.md` examples runnable and aligned with `docker-compose.yml` ports/URLs.

## Testing Guidelines

No automated tests are currently included. Validate changes by:
- running `docker compose up` and checking UIs load (NiFi `http://localhost:18443/nifi/`, Registry `http://localhost:18080/nifi-registry`, Kafka UI `http://localhost:8082/`);
- importing/updating a template from `nifi-templates/` and performing a small end-to-end smoke run.
If you need a clean slate for validation, use `docker compose down -v` (this wipes Postgres/NiFi/Registry state).

## Commit & Pull Request Guidelines

- Commit messages in history are short, descriptive, and written in Russian (e.g. “Доработки документации”, “Добавлены Postgres, Kafka…”). Follow the same style.
- PRs: include a short description, the motivation (issue link if applicable), and note any port/credential changes. Add screenshots for UI-facing doc updates when helpful.

## Security & Configuration Tips

This is for local learning, not production. Defaults include:
- NiFi single-user creds in `docker-compose.yml` (`admin` / `Password123456`);
- Postgres creds (`postgres` / `postgres`) and published port `5437`.
