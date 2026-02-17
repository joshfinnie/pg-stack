#!/bin/bash
set -euo pipefail

NAME=$1

if [ -z "$NAME" ]; then
	echo "Usage: ./drop_project.sh <project_name>"
	exit 1
fi

if [[ ! "$NAME" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
	echo "Error: project name must be alphanumeric/underscores only, starting with a letter or underscore"
	exit 1
fi

docker exec -i pg-core psql -U postgres <<EOF
DROP DATABASE IF EXISTS $NAME;
DROP USER IF EXISTS ${NAME}_user;
EOF

echo "Dropped project: $NAME"
