#!/bin/bash

docker exec -i pg-core psql -U postgres -c "\l"
