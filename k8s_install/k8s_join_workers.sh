#!/bin/bash

set -e

DEFAULT_NODES=(h2 h3 h4 h5)

if [[ $# -gt 0 ]]; then
    NODES=("$@")
else
    NODES=("${DEFAULT_NODES[@]}")
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
