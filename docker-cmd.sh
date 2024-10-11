#!/bin/bash
set -eu

echo "Munin for Docker v$(</run/version)..."

NODES="${NODES:-}"

# Set timezone
if ! [[ ! -z "$TZ" && -f "/usr/share/zoneinfo/$TZ" ]]; then
  TZ="UTC"
fi

cp "/usr/share/zoneinfo/$TZ" /etc/localtime
echo "$TZ" > /etc/timezone

#Make cgi-tmp directory before setting permissions
mkdir /var/lib/munin/cgi-tmp

# Fix ownership
chown munin:munin \
  /var/log/munin /run/munin /var/lib/munin /var/lib/munin/cgi-tmp \
  /etc/munin/munin-conf.d /etc/munin/plugin-conf.d

chmod 755 /usr/share/webapps/munin/html
chown -R munin:munin /usr/share/webapps/munin/html

# Prepare for rrdcached
sudo -u munin -- mkdir -p /var/lib/munin/rrdcached-journal
chown munin:munin /var/lib/munin/rrdcached-journal

# Start rrdcached
sudo -u munin -- /usr/sbin/rrdcached \
  -p /run/munin/rrdcached.pid \
  -B -b /var/lib/munin/ \
  -F -j /var/lib/munin/rrdcached-journal/ \
  -m 0660 -l unix:/run/munin/rrdcached.sock \
  -w 1800 -z 1800 -f 3600

# Generate node list
[[ ! -z "$NODES" ]] && for NODE in $NODES
do
  NAME=`echo "$NODE" | cut -d ":" -f1`
  HOST=`echo "$NODE" | cut -d ":" -f2`
  PORT=`echo "$NODE" | cut -d ":" -f3`
  if [ ${#PORT} -eq 0 ]; then
      PORT=4949
  fi
  if ! grep -q "$HOST" /etc/munin/munin-conf.d/nodes.conf 2>/dev/null ; then
    cat << EOF >> /etc/munin/munin-conf.d/nodes.conf
[$NAME]
    address $HOST
    use_node_name yes
    port $PORT

EOF
  fi
done

# Run once before we start fcgi
sudo -u munin -- /usr/bin/munin-cron munin

# Spawn fast cgi process for generating graphs on the fly
spawn-fcgi -s /var/run/munin/fastcgi-graph.sock -U nginx -u munin -g munin -- \
  /usr/share/webapps/munin/cgi/munin-cgi-graph

# Spawn fast cgi process for generating html on the fly
spawn-fcgi -s /var/run/munin/fastcgi-html.sock -U nginx -u munin -g munin -- \
  /usr/share/webapps/munin/cgi/munin-cgi-html

# Munin and logrotate runs in cron, start cron
crond

# Start web-server
nginx
