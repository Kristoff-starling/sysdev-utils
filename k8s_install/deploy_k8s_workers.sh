#!/bin/bash

set -e

SCRIPT="k8s_worker_setup.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

build_worker_nodes() {
    local cluster_size

    while true; do
        read -rp "How many nodes are in the cluster? " cluster_size
        if [[ "$cluster_size" =~ ^[0-9]+$ && "$cluster_size" -ge 2 ]]; then
            break
        fi
        echo "Please enter an integer greater than or equal to 2."
    done

    NODES=()
    for ((node = 2; node <= cluster_size; node++)); do
        NODES+=("h$node")
    done
}

if [[ $# -gt 0 ]]; then
    NODES=("$@")
else
    build_worker_nodes
fi

pids=()

for node in "${NODES[@]}"; do
    (
        echo "==> [$node] Copying $SCRIPT..."
        scp "$SCRIPT_DIR/$SCRIPT" "$node:/tmp/$SCRIPT"

        echo "==> [$node] Running $SCRIPT..."
        ssh "$node" "bash /tmp/$SCRIPT"

        echo "==> [$node] Done."
    ) &
    pids+=($!)
done

failed=0
for i in "${!pids[@]}"; do
    if ! wait "${pids[$i]}"; then
        echo "==> [${NODES[$i]}] FAILED"
        failed=1
    fi
done

if [[ $failed -eq 1 ]]; then
    echo "==> One or more nodes failed."
    exit 1
fi

echo "==> All nodes configured."
