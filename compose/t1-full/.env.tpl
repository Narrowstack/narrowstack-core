# T1 env template — op:// references only, never literal secret values.
# Inject with:  op run --env-file=compose/t1-full/.env.tpl -- deploy/green-check.sh <manifest>

# Postgres superuser (bootstrap only)
PG_SUPERUSER=postgres
PG_SUPERUSER_PASSWORD=op://Narrowstack/${TENANT}-core/PG_SUPERUSER_PASSWORD
PG_DATABASE=narrowstack
PG_PORT=5432

# Per-role credentials (bounded scope — see docs/plans secrets table)
DLT_PG_PASSWORD=op://Narrowstack/${TENANT}-core/DLT_PG_PASSWORD
DBT_PG_PASSWORD=op://Narrowstack/${TENANT}-core/DBT_PG_PASSWORD
MF_PG_PASSWORD=op://Narrowstack/${TENANT}-core/MF_PG_PASSWORD
APP_RO_PG_PASSWORD=op://Narrowstack/${TENANT}-core/APP_RO_PG_PASSWORD
AGENT_PG_PASSWORD=op://Narrowstack/${TENANT}-core/AGENT_PG_PASSWORD
