#!/bin/bash
set -eu

echo "Munin for Docker v$(</etc/version)..."

TZ="${TZ:-}"
NODES="${NODES:-}"
NODES_FILE="/etc/munin/munin-conf.d/nodes.generated.conf"

configureTimezone() {

  if [ -z "$TZ" ]; then
    return 0
  fi

  # Set timezone
  if [ ! -f "/usr/share/zoneinfo/$TZ" ]; then
    TZ="UTC"
  fi

  cp "/usr/share/zoneinfo/$TZ" /etc/localtime
  echo "$TZ" > /etc/timezone
}

prepareDirectories() {

  echo "Configuring permissions..."

  # Make directories before setting permissions
  mkdir -p /run/munin
  mkdir -p /var/run/munin
  mkdir -p /var/log/munin
  mkdir -p /var/lib/munin/cgi-tmp
  mkdir -p /var/lib/munin/rrdcached-journal

  # Fix ownership of runtime directories
  chown munin:munin \
    /run/munin \
    /var/run/munin \
    /var/log/munin \
    /var/lib/munin \
    /var/lib/munin/cgi-tmp \
    /var/lib/munin/rrdcached-journal \
    /etc/munin/munin-conf.d \
    /etc/munin/plugin-conf.d
}

cleanupRuntimeFiles() {

  # Remove stale runtime files
  rm -f /run/munin/rrdcached.pid
  rm -f /run/munin/rrdcached.sock
  rm -f /var/run/munin/fastcgi-graph.sock
  rm -f /var/run/munin/fastcgi-html.sock
}

fixWebPermissions() {

  # Fix permissions
  chmod 755 /usr/share/webapps/munin/html
  chown -R munin:munin /usr/share/webapps/munin/html
}

startRrdcached() {

  echo "Starting rrdcached..."

  # Start rrdcached
  sudo -u munin -- /usr/sbin/rrdcached \
    -p /run/munin/rrdcached.pid \
    -B -b /var/lib/munin/ \
    -F -j /var/lib/munin/rrdcached-journal/ \
    -m 0660 -l unix:/run/munin/rrdcached.sock \
    -w 1800 -z 1800 -f 3600
}

waitForRrdcached() {

  echo "Waiting for rrdcached socket to become available..."

  # Wait for rrdcached socket to become available
  until [ -S /run/munin/rrdcached.sock ]; do
    sleep 0.5
  done
}

addNode() {

  local node="$1"
  local name rest host port

  [ -z "$node" ] && return 0

  name="${node%%:*}"
  rest="${node#*:}"
  host="${rest%%:*}"
  port="${rest#*:}"

  [ "$rest" = "$node" ] && host=""
  [ "$port" = "$rest" ] && port="4949"
  [ -z "$port" ] && port="4949"

  if [ -z "$name" ] || [ -z "$host" ]; then
    echo "Skipping invalid node definition: $node" >&2
    return 0
  fi

  {
    printf '[%s]\n' "$name"
    printf '    address %s\n' "$host"
    printf '    use_node_name yes\n'
    printf '    port %s\n' "$port"
    printf '\n'
  } >> "$NODES_FILE"
}

hasConfiguredNode() {

  local file

  while IFS= read -r -d '' file; do
    [ "$file" = "$NODES_FILE" ] && continue

    if awk '
      FNR == 1 {
        is_node = 0
        found = 0
      }

      {
        line = $0
        sub(/[[:space:]]*#.*/, "", line)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      }

      line == "" {
        next
      }

      line ~ /^\[[^]]+\]$/ {
        section = line
        sub(/^\[/, "", section)
        sub(/\]$/, "", section)
        is_node = section !~ /;$/
        next
      }

      is_node {
        found = 1
        exit
      }

      END {
        exit found ? 0 : 1
      }
    ' "$file"; then
      return 0
    fi
  done < <(find -L "${NODES_FILE%/*}" -maxdepth 1 -type f -print0)

  return 1
}

configureNodes() {

  local nodes node

  # Generate node list
  rm -f "$NODES_FILE"

  if [ -z "$NODES" ]; then
    if hasConfiguredNode; then
      return 0
    fi

    {
      printf '[dummy]\n'
      printf '    update no\n'
      printf '\n'
    } > "$NODES_FILE"

    chown munin:munin "$NODES_FILE"
    return 0
  fi

  : > "$NODES_FILE"
  nodes="$(printf '%s\n' "$NODES" | tr ',[:space:]' '\n')"

  while IFS= read -r node; do
    addNode "$node"
  done <<< "$nodes"

  chown munin:munin "$NODES_FILE"
}

runMuninCronOnce() {

  echo "Starting Munin..."

  # Run once before we start fcgi
  sudo -u munin -- /usr/bin/munin-cron munin
}

startFastcgi() {

  echo "Starting fastcgi process..."

  # Spawn fast cgi process for generating graphs on the fly
  spawn-fcgi -s /var/run/munin/fastcgi-graph.sock -U nginx -u munin -g munin -- \
    /usr/share/webapps/munin/cgi/munin-cgi-graph

  # Spawn fast cgi process for generating html on the fly
  spawn-fcgi -s /var/run/munin/fastcgi-html.sock -U nginx -u munin -g munin -- \
    /usr/share/webapps/munin/cgi/munin-cgi-html
}

startCron() {

  echo "Starting cron..."

  # Munin and logrotate runs in cron, start cron
  crond
}

startWebServer() {

  # Start web-server
  nginx
}

configureTimezone
prepareDirectories
cleanupRuntimeFiles
fixWebPermissions
startRrdcached
waitForRrdcached
configureNodes
runMuninCronOnce
startFastcgi
startCron

echo "Munin started successfully!"
startWebServer
