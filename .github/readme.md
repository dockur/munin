<h1 align="center">Munin for Docker<br />
<div align="center">
<a href="https://github.com/dockur/munin"><img src="https://raw.githubusercontent.com/dockur/munin/master/.github/logo.jpg" title="Logo" style="max-width:100%;" width="192" /></a>
</div>
<div align="center">

[![Build]][build_url]
[![Version]][tag_url]
[![Size]][tag_url]
[![Package]][pkg_url]
[![Pulls]][hub_url]

</div></h1>

Container image for a [Munin](https://munin-monitoring.org/) master server.

## Features ✨

* `rrdcached` is used to be able to handle a large number of nodes.

* `fcgi` is used for generation of graphs on demand and not cron.

## Usage  🐳

##### Via Docker Compose:

```yaml
services:
  munin:
    image: dockurr/munin
    container_name: munin
    environment:
      TZ: "Europe/Amsterdam"
      NODES: "node1:10.0.0.101 node2:10.0.0.102"
    ports:
      - 80:80
    volumes:
      - ./lib:/var/lib/munin
      - ./log:/var/log/munin
      - ./conf:/etc/munin/munin-conf.d
      - ./plugin:/etc/munin/plugin-conf.d
    restart: always
    stop_grace_period: 1m
```

##### Via Docker CLI:

```bash
docker run -it --rm --name munin -p 80:80 -e "NODES=node1:10.0.0.101 node2:10.0.0.102" --stop-timeout 60 docker.io/dockurr/munin
```

 # Acknowledgements 🙏
 
Special thanks to [@aheimsbakk](https://github.com/aheimsbakk), for creating the original project.

## Stars 🌟
[![Stars](https://starchart.cc/dockur/munin.svg?variant=adaptive)](https://starchart.cc/dockur/munin)

[build_url]: https://github.com/dockur/munin/
[hub_url]: https://hub.docker.com/r/dockurr/munin
[tag_url]: https://hub.docker.com/r/dockurr/munin/tags
[pkg_url]: https://github.com/dockur/munin/pkgs/container/munin

[Build]: https://github.com/dockur/munin/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/dockurr/munin/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/dockurr/munin.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/dockurr/munin/latest?arch=amd64&sort=semver&color=066da5
[Package]:https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fipitio.github.io%2Fbackage%2Fdockur%2Fmunin%2Fmunin.json&query=%24.downloads&logo=github&style=flat&color=066da5&label=pulls
