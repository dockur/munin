FROM alpine:3.18.4

# Install packages
RUN apk --update --no-cache add \
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
  ;

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
ENV NODES ""

# Expose nginx
EXPOSE 80

# Container version
ARG DATE_ARG=""
ARG BUILD_ARG=0
ARG VERSION_ARG="0.0"
ENV VERSION=$VERSION_ARG

LABEL org.opencontainers.image.created=${DATE_ARG}
LABEL org.opencontainers.image.revision=${BUILD_ARG}
LABEL org.opencontainers.image.version=${VERSION_ARG}
LABEL org.opencontainers.image.url=https://hub.docker.com/r/dockurr/munin/
LABEL org.opencontainers.image.source=https://github.com/dockur/munin/

# Healthcheck
HEALTHCHECK --interval=60s --retries=2 --timeout=10s CMD wget -nv -t1 --spider 'http://localhost:80/munin/' || exit 1

# Use dumb-init since we run a lot of processes
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Run start script or what you choose
CMD /bin/bash /docker-cmd.sh
