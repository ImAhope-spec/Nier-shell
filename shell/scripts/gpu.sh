#!/bin/sh
# Загрузка GPU в процентах. AMD: sysfs, NVIDIA: nvidia-smi. Иначе -1.
v=""
for f in /sys/class/drm/card*/device/gpu_busy_percent; do
  [ -r "$f" ] && v=$(cat "$f") && break
done
[ -z "$v" ] && v=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
echo "${v:--1}"
