#!/usr/bin/env bash
# system_health.sh - Robust system health checker
# Logs to $LOGFILE and prints alerts to console (unless SILENT=true).
# Defaults can be overridden via environment variables.

LOGFILE="${LOGFILE:-$HOME/sys_health.log}"
CPU_WARN="${CPU_WARN:-80}"          # percent
MEM_WARN="${MEM_WARN:-80}"          # percent
DISK_WARN="${DISK_WARN:-85}"        # percent
PROCS_TO_CHECK="${PROCS_TO_CHECK:-docker,kubelet}"  # comma-separated substrings
DISK_MOUNT="${DISK_MOUNT:-/}"       # mountpoint to check
SILENT="${SILENT:-false}"           # if true, no console output for alerts

timestamp(){ date '+%Y-%m-%d %H:%M:%S'; }
log(){ echo "$(timestamp) $*" >> "$LOGFILE"; }
alert(){ local m="$*"; log "ALERT: $m"; if [ "$SILENT" != "true" ]; then echo "ALERT: $m"; fi }

# CPU usage percent — robust read of /proc/stat
cpu_usage_percent(){
  # Read fields safely (some kernels include different fields)
  read -r u1 n1 s1 i1 w1 x1 y1 z1 <<< "$(awk '/^cpu /{for(i=2;i<=9;i++) printf "%s ",$i; print ""}' /proc/stat)"
  u1=${u1:-0}; n1=${n1:-0}; s1=${s1:-0}; i1=${i1:-0}; w1=${w1:-0}; x1=${x1:-0}; y1=${y1:-0}; z1=${z1:-0}
  total1=$((u1+n1+s1+i1+w1+x1+y1+z1))
  idle1=$((i1 + w1))

  sleep 1

  read -r u2 n2 s2 i2 w2 x2 y2 z2 <<< "$(awk '/^cpu /{for(i=2;i<=9;i++) printf "%s ",$i; print ""}' /proc/stat)"
  u2=${u2:-0}; n2=${n2:-0}; s2=${s2:-0}; i2=${i2:-0}; w2=${w2:-0}; x2=${x2:-0}; y2=${y2:-0}; z2=${z2:-0}
  total2=$((u2+n2+s2+i2+w2+x2+y2+z2))
  idle2=$((i2 + w2))

  diff=$((total2 - total1))
  idle_diff=$((idle2 - idle1))
  if [ "$diff" -le 0 ]; then
    echo 0
    return
  fi
  busy=$((diff - idle_diff))
  pct=$(( (100*busy + diff/2) / diff ))
  echo "$pct"
}

mem_usage_percent(){
  local mem_total mem_avail used pct
  mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  mem_avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  mem_total=${mem_total:-0}; mem_avail=${mem_avail:-0}
  if [ "$mem_total" -le 0 ]; then echo 0; return; fi
  used=$((mem_total - mem_avail))
  pct=$(( (used * 100 + mem_total/2) / mem_total ))
  echo "$pct"
}

disk_usage_percent(){
  local out
  out=$(df -P "$DISK_MOUNT" 2>/dev/null | awk 'NR==2{gsub(/%/,"",$5); print $5}')
  out=${out:-0}
  echo "$out"
}

check_processes(){
  IFS=',' read -ra procs <<< "$PROCS_TO_CHECK"
  for p in "${procs[@]}"; do
    cnt=$(ps aux | grep -i "$p" | grep -v grep | wc -l)
    if [ "$cnt" -lt 1 ]; then
      alert "Process [$p] not running (count=$cnt)"
    fi
  done
}

main(){
  mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null || true
  log "Running system health check"

  cpu=$(cpu_usage_percent)
  mem=$(mem_usage_percent)
  disk=$(disk_usage_percent)

  log "CPU=${cpu}% MEM=${mem}% DISK=${disk}%"

  if [ -n "$cpu" ] && [ "$cpu" -ge "$CPU_WARN" ] 2>/dev/null; then
    alert "CPU usage high: ${cpu}% (threshold ${CPU_WARN}%)"
  fi

  if [ -n "$mem" ] && [ "$mem" -ge "$MEM_WARN" ] 2>/dev/null; then
    alert "Memory usage high: ${mem}% (threshold ${MEM_WARN}%)"
  fi

  if [ -n "$disk" ] && [ "$disk" -ge "$DISK_WARN" ] 2>/dev/null; then
    alert "Disk usage on ${DISK_MOUNT} high: ${disk}% (threshold ${DISK_WARN}%)"
  fi

  if [ -n "$PROCS_TO_CHECK" ]; then
    check_processes
  fi
}

main

