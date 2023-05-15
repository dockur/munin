munin-docker
=============

[![Build]][build_url]
[![Version]][tag_url]
[![Size]][tag_url]
[![Pulls]][hub_url]

Container image for a Munin server, optimized for a large number of hosts in an effective manner.

* `rrdcached` is used to be able to handle a large number of hosts

* `fcgi` is used for generation of graphs on demand and not cron

## Environment variables

* `NODES`

    Format `[group1;]node1:ip1[:port1] [group2;]node2:ip2[:port2]...`

* `SNMP_NODES`

    Format `[group1;]node1:commutiy1: [group2;]node2:community2:...`

    Check SNMP units directly from the container. Defaults to SNMP version 2c.

* `TZ`

    Time zone. Defaults to `UTC`.

## Exposed ports

* `80`

## Volumes

* `/etc/munin/munin-conf.d/`

    Configuration files included on runtime. The files `nodes.conf` and `snmp-nodes.conf` are generated by this container.

* `/etc/munin/plugin-conf.d/`

    Configuration files for plugins. The file `snmp_communities` is generated by this container, but custom changes will not be overwritten.

* `/var/lib/munin/`

    All RRD files and temporary files.

* `/var/log/munin/`

    Log files.

## How to use this container

```
docker run -d \
  -p 80:80 --name munin-server \
  -v /var/lib/munin:/var/lib/munin \
  -v /var/log/munin:/var/log/munin \
  -v /etc/munin/munin-conf.d:/etc/munin/munin-conf.d \
  -v /etc/munin/plugin-conf.d:/etc/munin/plugin-conf.d \
  -e NODES="server1:10.0.0.2 server2:10.1.0.2" \
  dockur/docker-munin
```

Access container at `http://host/munin/`

[build_url]: https://github.com/dockur/docker-munin/
[hub_url]: https://hub.docker.com/r/dockur/docker-munin
[tag_url]: https://hub.docker.com/r/dockur/docker-munin/tags

[Build]: https://github.com/dockur/docker-munin/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/dockur/docker-munin/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/dockur/docker-munin.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/dockur/docker-munin?arch=amd64&sort=date&color=066da5
