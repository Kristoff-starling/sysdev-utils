#!/bin/bash

set -euo pipefail

disable_boost() {
    local vendor
    vendor="$(awk -F: '/vendor_id/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo || true)"

    case "$vendor" in
        GenuineIntel)
            if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
                echo "1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
                return 0
            fi
            ;;
        AuthenticAMD)
            if [[ -f /sys/devices/system/cpu/amd_pstate/cpb_boost ]]; then
                echo "0" | sudo tee /sys/devices/system/cpu/amd_pstate/cpb_boost
                return 0
            fi
            if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
                echo "0" | sudo tee /sys/devices/system/cpu/cpufreq/boost
                return 0
            fi
            ;;
    esac

    local found=0
    for boost_file in /sys/devices/system/cpu/cpu*/cpufreq/boost; do
        if [[ -e "$boost_file" ]]; then
            echo "0" | sudo tee "$boost_file"
            found=1
        fi
    done

    if [[ "$found" -eq 0 ]]; then
        echo "warning: no CPU boost control found for vendor ${vendor:-unknown}" >&2
    fi
}

set_performance_governor() {
    local found=0
    for gov_file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -e "$gov_file" ]]; then
            echo "performance" | sudo tee "$gov_file"
            found=1
        fi
    done

    if [[ "$found" -eq 0 ]]; then
        echo "warning: no scaling_governor sysfs entries found" >&2
    fi
}

disable_boost
set_performance_governor

# Disable CPU idle states.
sudo cpupower idle-set -D 0

# Disable address space randomization.
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
