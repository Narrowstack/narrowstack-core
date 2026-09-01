# op:// references only — inject with: op run --env-file=.env.tpl -- docker compose up
PG_DATABASE=narrowstack
PG_SUPERUSER=postgres
PG_SUPERUSER_PASSWORD=op://Narrowstack/example-core/PG_SUPERUSER_PASSWORD
PG_PORT=5432
