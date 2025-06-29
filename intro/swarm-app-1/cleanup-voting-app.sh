#!/usr/bin/env bash

set -euo pipefail

echo "=== Removing services ==="
for service in vote redis worker db result; do
  if docker service ls | grep -q "\s$service\s"; then
    echo "Removing service: $service"
    docker service rm "$service"
  else
    echo "Service $service does not exist"
  fi
done

echo "=== Removing overlay networks ==="
for network in frontend backend; do
  if docker network ls | grep -q "\s$network\s"; then
    echo "Removing network: $network"
    docker network rm "$network"
  else
    echo "Network $network does not exist"
  fi
done

echo "=== Removing volume ==="
if docker volume ls | grep -q '\sdb-data\s'; then
  docker volume rm db-data
else
  echo "Volume db-data does not exist"
fi

echo "=== Leaving Docker Swarm (if applicable) ==="
if docker info | grep -q 'Swarm: active'; then
  docker swarm leave --force
  echo "Left Docker Swarm"
else
  echo "Not part of a Docker Swarm"
fi

echo "✅ Cleanup complete."
