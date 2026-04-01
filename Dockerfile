# syntax=docker/dockerfile:1

FROM alpine:edge

ARG VERSION_ARG="0.0"
    
# Install packages
RUN set -eu && \
    apk update && \
    apk upgrade && \
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
    tzdata && \
  echo "$VERSION_ARG" > /run/version && \
  rm -rf /var/cache/apk/*

# Create the user and group
# RUN addgroup -S munin && adduser -S munin -G munin

# Set munin crontab
RUN sed '/^[^*].*$/d; s/ munin //g' /etc/munin/munin.cron.sample | crontab -u munin - 

# Default nginx.conf
COPY nginx.conf /etc/nginx/

# Copy munin config to nginx
COPY default.conf /etc/nginx/conf.d/

# Copy munin conf
COPY munin.conf /etc/munin/

# Start script with all processes
COPY docker-cmd.sh /

# Set execute permission
RUN chmod +x /docker-cmd.sh

# Logrotate script for munin logs
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
CMD ["/bin/bash", "/docker-cmd.sh"]
