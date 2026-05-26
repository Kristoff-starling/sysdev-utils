#!/bin/bash

set -e

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

echo "==> Generating join command from control plane..."
JOIN_CMD=$(kubeadm token create --print-join-command)
echo "==> Join command: $JOIN_CMD"

pids=()

for node in "${NODES[@]}"; do
    (
        echo "==> [$node] Joining cluster..."
        ssh "$node" "sudo $JOIN_CMD"
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
    echo "==> One or more nodes failed to join."
    exit 1
fi

echo "==> All nodes joined the cluster."
