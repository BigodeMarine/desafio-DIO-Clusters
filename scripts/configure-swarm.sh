#!/usr/bin/env bash
set -euo pipefail

node_name="$1"
node_ip="$2"
manager_ip="$3"
shared_dir=/vagrant/.swarm
state=$(docker info --format '{{.Swarm.LocalNodeState}}')

if [[ "$node_name" == "master" ]]; then
  # O IP privado evita anunciar a interface NAT, igual em todas as VMs.
  if [[ "$state" == "inactive" ]]; then
    docker swarm init --advertise-addr "$node_ip" --data-path-addr "$node_ip"
  fi
  if [[ $(docker info --format '{{.Swarm.ControlAvailable}}') != "true" ]]; then
    echo "Erro: master não é manager. Verifique o Swarm existente." >&2
    exit 1
  fi

  # Publicação atômica para os workers nunca lerem um token incompleto.
  mkdir -p "$shared_dir"
  docker swarm join-token -q worker > "$shared_dir/worker-token.tmp"
  mv "$shared_dir/worker-token.tmp" "$shared_dir/worker-token"
  echo "Manager pronto em ${manager_ip}:2377."
  exit 0
fi

if [[ "$state" == "active" ]]; then
  if [[ $(docker info --format '{{.Swarm.ControlAvailable}}') == "true" ]]; then
    echo "Erro: ${node_name} está como manager; esperado worker." >&2
    exit 1
  fi
  echo "${node_name} já participa de um Swarm. Nenhuma alteração realizada."
  exit 0
fi

# Aguarda por até 5 minutos; o README inicia o manager antes dos workers.
for attempt in $(seq 1 60); do
  if [[ -s "$shared_dir/worker-token" ]]; then
    token=$(cat "$shared_dir/worker-token")
    if docker swarm join --token "$token" --advertise-addr "$node_ip" \
      --data-path-addr "$node_ip" "${manager_ip}:2377"; then
      echo "${node_name} incluído como worker."
      exit 0
    fi
  fi
  sleep 5
done

echo "Erro: não foi possível incluir ${node_name}. Confira o manager e a rede." >&2
exit 1
