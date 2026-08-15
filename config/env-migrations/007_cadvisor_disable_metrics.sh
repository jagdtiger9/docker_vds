#!/bin/bash
# Add CADVISOR_DISABLE_METRICS param
set -e

ENV="$1"

# Already applied?
grep -q '^CADVISOR_DISABLE_METRICS=' "$ENV" && exit 0

echo "[007] Adding CADVISOR_DISABLE_METRICS"

sed -i '/^CONF_MYSQL_EXPORTER=/a CADVISOR_DISABLE_METRICS=advtcp,cpuset,hugetlb,memory_numa,percpu,process,resctrl,accelerator,sched,schedstat,tcp,udp' "$ENV"
