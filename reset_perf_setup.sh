#!/bin/bash

set -euo pipefail

enable_boost() {
    local vendor
    vendor="$(awk -F: '/vendor_id/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo || true)"

    case "$vendor" in
        GenuineIntel)
            if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
                echo "0" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null
                echo "intel turbo re-enabled via intel_pstate/no_turbo=0"
                return 0
            fi
            ;;
        AuthenticAMD)
            if [[ -f /sys/devices/system/cpu/amd_pstate/cpb_boost ]]; then
                echo "1" | sudo tee /sys/devices/system/cpu/amd_pstate/cpb_boost >/dev/null
                echo "amd boost re-enabled via amd_pstate/cpb_boost=1"
                return 0
            fi
            if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
                echo "1" | sudo tee /sys/devices/system/cpu/cpufreq/boost >/dev/null
                echo "amd boost re-enabled via cpufreq/boost=1"
                return 0
            fi
            ;;
    esac

    local found=0
    for boost_file in /sys/devices/system/cpu/cpu*/cpufreq/boost; do
        if [[ -e "$boost_file" ]]; then
            echo "1" | sudo tee "$boost_file" >/dev/null
            found=1
        fi
    done

    if [[ "$found" -eq 1 ]]; then
        echo "per-cpu boost knobs re-enabled"
    else
        echo "warning: no boost control sysfs entries found; reboot may be required to fully restore firmware defaults" >&2
    fi
}

restore_governor() {
    local target=""

    if cpupower frequency-info 2>/dev/null | grep -q 'available cpufreq governors'; then
        local governors
        governors="$(cpupower frequency-info 2>/dev/null | awk -F: '/available cpufreq governors/ {gsub(/^[ \t]+/, "", $2); print $2; exit}')"
        if [[ "$governors" == *schedutil* ]]; then
            target="schedutil"
        elif [[ "$governors" == *ondemand* ]]; then
            target="ondemand"
        elif [[ "$governors" == *powersave* ]]; then
            target="powersave"
        fi
    fi

    if [[ -z "$target" ]]; then
        echo "warning: no restorable cpufreq governor detected; leaving governor unchanged" >&2
        return 0
    fi

    local found=0
    for gov_file in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -e "$gov_file" ]]; then
            echo "$target" | sudo tee "$gov_file" >/dev/null
            found=1
        fi
    done

    if [[ "$found" -eq 1 ]]; then
        echo "scaling governor set to $target"
    else
        echo "warning: no scaling_governor sysfs entries found; leaving governor unchanged" >&2
    fi
}

enable_idle_states() {
    if cpupower idle-info 2>/dev/null | grep -q 'No idle states'; then
        echo "cpuidle driver exposes no idle states; nothing to re-enable"
        return 0
    fi

    sudo cpupower idle-set -E
    echo "cpu idle states re-enabled"
}

restore_aslr() {
    echo 2 | sudo tee /proc/sys/kernel/randomize_va_space >/dev/null
    echo "ASLR restored to randomize_va_space=2"
}

enable_boost
restore_governor
enable_idle_states
restore_aslr
