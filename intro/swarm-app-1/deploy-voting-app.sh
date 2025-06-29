#!/usr/bin/env bash

set -euo pipefail

echo "=== Checking if Docker Swarm is already initialized ==="
if ! docker info | grep -q 'Swarm: active'; then
  echo "Initializing Docker Swarm..."
  docker swarm init
else
  echo "Docker Swarm already initialized."
fi

echo "=== Creating overlay networks ==="
docker network create --driver overlay frontend || echo "Overlay network 'frontend' already exists"
docker network create --driver overlay backend || echo "Overlay network 'backend' already exists"

echo "=== Creating named volume for PostgreSQL ==="
docker volume create db-data || echo "Volume 'db-data' already exists"

echo "=== Deploying vote service (frontend) ==="
if ! docker service ls | grep -q '\svote\s'; then
  docker service create \
    --name vote \
    --replicas 2 \
    --publish 80:80 \
    --network frontend \
    bretfisher/examplevotingapp_vote
else
  echo "Service 'vote' already exists"
fi

echo "=== Deploying redis service (in-memory store) ==="
if ! docker service ls | grep -q '\sredis\s'; then
  docker service create \
    --name redis \
    --network frontend \
    redis:3.2
else
  echo "Service 'redis' already exists"
fi

echo "=== Deploying worker service (backend processor) ==="
if ! docker service ls | grep -q '\sworker\s'; then
  docker service create \
    --name worker \
    --network frontend \
    --network backend \
    bretfisher/examplevotingapp_worker
else
  echo "Service 'worker' already exists"
fi

echo "=== Deploying db service (PostgreSQL) ==="
if ! docker service ls | grep -q '\sdb\s'; then
  docker service create \
    --name db \
    --network backend \
    --mount type=volume,source=db-data,target=/var/lib/postgresql/data \
    -e POSTGRES_HOST_AUTH_METHOD="trust" \
    postgres:9.4
else
  echo "Service 'db' already exists"
fi

echo "=== Deploying result service (admin results UI) ==="
if ! docker service ls | grep -q '\sresult\s'; then
  docker service create \
    --name result \
    --publish 5001:80 \
    --network backend \
    bretfisher/examplevotingapp_result
else
  echo "Service 'result' already exists"
fi

echo "✅ All services launched. Run 'docker service ls' to confirm."
