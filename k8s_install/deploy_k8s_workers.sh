#!/bin/bash

set -e

SCRIPT="k8s_worker_setup.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_NODES=(h2 h3 h4 h5)

if [[ $# -gt 0 ]]; then
    NODES=("$@")
else
    NODES=("${DEFAULT_NODES[@]}")
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
