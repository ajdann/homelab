#!/usr/bin/env bash
# Run Tailscale agent playbook from project root. Use from WSL:
#   cd /mnt/d/work/homelab  # or your repo path
#   bash infra/ansible/run-tailscale-agent.sh

set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"
ansible-playbook -i infra/ansible/inventory/single-node.yaml infra/ansible/playbooks/tailscale-agent.yaml -v "$@"
