# syntax=docker/dockerfile:1

FROM alpine:edge

ARG MUNIN_UID=100
ARG MUNIN_GID=101
ARG VERSION_ARG="0.0"
    
RUN <<EOF
set -eu

apk update
apk upgrade

# Install packages
apk --no-cache add \
  coreutils \
  dumb-init \
  findutils \
  logrotate \
  munin \
  munin-node \
  nginx \
  perl-cgi-fast \
  procps \
  rrdtool-cached \
  spawn-fcgi \
  sudo \
  ttf-opensans \
  tzdata \
  shadow

rm -rf /var/cache/apk/*

# Set Munin user and group IDs
deluser klogd 2>/dev/null || true
delgroup klogd 2>/dev/null || true
groupmod -g "$MUNIN_GID" munin
usermod -u "$MUNIN_UID" -g "$MUNIN_GID" munin

# Set Munin crontab
sed '/^[^*].*$/d; s/ munin //g' /etc/munin/munin.cron.sample | crontab -u munin -

# Patch Munin RRDTool 1.10 version check
update_worker="/usr/share/perl5/vendor_perl/Munin/Master/UpdateWorker.pm"
graph_old="/usr/share/perl5/vendor_perl/Munin/Master/GraphOld.pm"

grep -q '} elsif($RRDs::VERSION < 1\.3){' "$update_worker"
grep -q 'if ($RRDs::VERSION >= 1\.3){' "$graph_old"

sed -i 's/} elsif($RRDs::VERSION < 1\.3){/} elsif(0){/' "$update_worker"
sed -i 's/if ($RRDs::VERSION >= 1\.3){/if (1){/' "$graph_old"

# Set version number
echo "$VERSION_ARG" > /etc/version
EOF

# Default nginx.conf
COPY nginx.conf /etc/nginx/

# Copy Munin config to nginx
COPY default.conf /etc/nginx/conf.d/

# Copy Munin conf
COPY munin.conf /etc/munin/

# Start script with all processes
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# Logrotate script for Munin logs
COPY munin /etc/logrotate.d/

# Expose volumes
VOLUME /etc/munin/munin-conf.d /etc/munin/plugin-conf.d /var/lib/munin /var/log/munin

# Expose NODES variable
ENV NODES=""

# Expose nginx
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=60s --retries=2 --timeout=10s CMD wget -nv -t1 --spider 'http://localhost:80/munin/' || exit 1

# Use dumb-init since we run a lot of processes
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Run start script or what you choose
CMD ["/bin/bash", "/entrypoint.sh"]
