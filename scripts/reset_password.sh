#!/bin/bash
set -euo pipefail

NAME=$1

if [ -z "$NAME" ]; then
	echo "Usage: ./reset_password.sh <project_name>"
	exit 1
fi

if [[ ! "$NAME" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
	echo "Error: project name must be alphanumeric/underscores only, starting with a letter or underscore"
	exit 1
fi

USER="${NAME}_user"
PASS=$(openssl rand -base64 24 | tr -d '=+/')
SERVER_IP=$(curl -s ifconfig.me)

docker exec -i pg-core psql -U postgres <<EOF
ALTER USER $USER WITH PASSWORD '$PASS';
EOF

CONN="postgres://$USER:$PASS@$SERVER_IP:6432/$NAME"

# Update secrets/projects.csv if it exists
if [ -f secrets/projects.csv ]; then
	sed -i.bak "/^$NAME,/d" secrets/projects.csv
	rm -f secrets/projects.csv.bak
	echo "$NAME,$USER,$PASS,$CONN" >>secrets/projects.csv
fi

echo "========================================"
echo "Password reset"
echo "DB:   $NAME"
echo "USER: $USER"
echo "PASS: $PASS"
echo "URL:  $CONN"
echo "========================================"
