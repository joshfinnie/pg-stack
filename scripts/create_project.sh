#!/bin/bash
set -euo pipefail

NAME=$1

if [ -z "$NAME" ]; then
	echo "Usage: ./create_project.sh <project_name>"
	exit 1
fi

if [[ ! "$NAME" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
	echo "Error: project name must be alphanumeric/underscores only, starting with a letter or underscore"
	exit 1
fi

DB_USER="${NAME}_user"
PASS=$(openssl rand -base64 24 | tr -d '=+/')
SERVER_IP=$(curl -s ifconfig.me)

echo "Creating DB: $NAME"

docker exec -i pg-core psql -U postgres <<EOF
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$NAME') THEN
      CREATE DATABASE $NAME;
   END IF;
END
\$\$;

DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
      CREATE USER $DB_USER WITH PASSWORD '$PASS';
   END IF;
END
\$\$;

GRANT ALL PRIVILEGES ON DATABASE $NAME TO $DB_USER;
EOF

docker exec -i pg-core psql -U postgres -d "$NAME" <<EOF
GRANT ALL ON SCHEMA public TO $DB_USER;
EOF

CONN="postgres://$DB_USER:$PASS@$SERVER_IP:6432/$NAME"

echo ""
echo "========================================"
echo "Project created"
echo "DB:   $NAME"
echo "USER: $DB_USER"
echo "PASS: $PASS"
echo "URL:  $CONN"
echo "========================================"

mkdir -p secrets
echo "$NAME,$DB_USER,$PASS,$CONN" >>secrets/projects.csv
