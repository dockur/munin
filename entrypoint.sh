#!/bin/bash
set -eu

echo "Munin for Docker v$(</etc/version)..."

TZ="${TZ:-}"
NODES="${NODES:-}"

if [ -n "$TZ" ]; then

  # Set timezone
  if [ ! -f "/usr/share/zoneinfo/$TZ" ]; then
    TZ="UTC"
  fi

  cp "/usr/share/zoneinfo/$TZ" /etc/localtime
  echo "$TZ" > /etc/timezone

fi

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

# Remove stale runtime files
rm -f /run/munin/rrdcached.pid
rm -f /run/munin/rrdcached.sock
rm -f /var/run/munin/fastcgi-graph.sock
rm -f /var/run/munin/fastcgi-html.sock

# Fix permissions
chmod 755 /usr/share/webapps/munin/html
chown -R munin:munin /usr/share/webapps/munin/html

echo "Starting rrdcached..."

# Start rrdcached
sudo -u munin -- /usr/sbin/rrdcached \
  -p /run/munin/rrdcached.pid \
  -B -b /var/lib/munin/ \
  -F -j /var/lib/munin/rrdcached-journal/ \
  -m 0660 -l unix:/run/munin/rrdcached.sock \
  -w 1800 -z 1800 -f 3600

echo "Waiting for rrdcached socket to become available..."

# Wait for rrdcached socket to become available
until [ -S /run/munin/rrdcached.sock ]; do
  sleep 0.5
done

# Generate node list
if [ -n "$NODES" ]; then

  nodes="$(printf '%s\n' "$NODES" | tr ',' '\n')"

  while IFS= read -r NODE; do

    [ -z "$NODE" ] && continue

    NAME="${NODE%%:*}"
    REST="${NODE#*:}"
    HOST="${REST%%:*}"
    PORT="${REST#*:}"

    [ "$REST" = "$NODE" ] && HOST=""
    [ "$PORT" = "$REST" ] && PORT="4949"
    [ -z "$PORT" ] && PORT="4949"

    if [ -z "$NAME" ] || [ -z "$HOST" ]; then
      echo "Skipping invalid node definition: $NODE" >&2
      continue
    fi

    if ! grep -Fxq "    address $HOST" /etc/munin/munin-conf.d/nodes.conf 2>/dev/null; then
      {
        printf '[%s]\n' "$NAME"
        printf '    address %s\n' "$HOST"
        printf '    use_node_name yes\n'
        printf '    port %s\n' "$PORT"
        printf '\n'
      } >> /etc/munin/munin-conf.d/nodes.conf
    fi

  done <<< "$nodes"

  chown munin:munin /etc/munin/munin-conf.d/nodes.conf

fi

echo "Starting Munin..."

# Run once before we start fcgi
sudo -u munin -- /usr/bin/munin-cron munin

echo "Starting fastcgi process..."

# Spawn fast cgi process for generating graphs on the fly
spawn-fcgi -s /var/run/munin/fastcgi-graph.sock -U nginx -u munin -g munin -- \
  /usr/share/webapps/munin/cgi/munin-cgi-graph

# Spawn fast cgi process for generating html on the fly
spawn-fcgi -s /var/run/munin/fastcgi-html.sock -U nginx -u munin -g munin -- \
  /usr/share/webapps/munin/cgi/munin-cgi-html

echo "Starting cron..."

# Munin and logrotate runs in cron, start cron
crond

echo "Munin started successfully!"

# Start web-server
nginx
