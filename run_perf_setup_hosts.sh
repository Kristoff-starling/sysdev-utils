#!/bin/bash

set -euo pipefail

script_name="perf_setup.sh"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
local_script="$script_dir/$script_name"
remote_script="/tmp/$script_name"

usage() {
    cat <<'EOF'
Usage: run_perf_setup_hosts.sh [host...]

SSH into each target host and run ~/sysdev-utils/perf_setup.sh.
If no hosts are provided, prompts for the cluster size and targets h2..hN.

Examples:
  ./run_perf_setup_hosts.sh
  ./run_perf_setup_hosts.sh h2 h5
EOF
}

build_worker_hosts() {
    local cluster_size

    while true; do
        read -rp "How many nodes are in the cluster? " cluster_size
        if [[ "$cluster_size" =~ ^[0-9]+$ && "$cluster_size" -ge 2 ]]; then
            break
        fi
        echo "Please enter an integer greater than or equal to 2."
    done

    hosts=()
    for ((node = 2; node <= cluster_size; node++)); do
        hosts+=("h$node")
    done
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [[ "$#" -gt 0 ]]; then
    hosts=("$@")
else
    build_worker_hosts
fi

if [[ ! -f "$local_script" ]]; then
    echo "missing local script: $local_script"
    exit 1
fi

failures=0
pids=()

for host in "${hosts[@]}"; do
    (
        echo "=== $host ==="
        echo "[$host] copying $script_name"
        scp "$local_script" "$host:$remote_script"

        echo "[$host] running $remote_script"
        ssh -t "$host" "bash $remote_script"

        echo "[$host] ok"
        echo
    ) &
    pids+=($!)
done

for i in "${!pids[@]}"; do
    if ! wait "${pids[$i]}"; then
        echo "[${hosts[$i]}] failed"
        failures=$((failures + 1))
    fi
done

if [[ "$failures" -gt 0 ]]; then
    echo "$failures host(s) failed"
    exit 1
fi

echo "all hosts succeeded"
