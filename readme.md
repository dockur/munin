<h1 align="center">Munin for Docker<br />
<div align="center">
<a href="https://github.com/dockur/munin"><img src="https://raw.githubusercontent.com/dockur/munin/master/.github/logo.png" title="Logo" style="max-width:100%;" width="192" /></a>
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

- Provides a Munin master monitoring server
- Displays monitoring graphs through a web interface
- Supports monitoring multiple Munin nodes
- Uses `rrdcached` for better performance
- Generates graphs on demand with FastCGI
- Supports custom Munin configuration
- Lightweight Alpine-based image

## Usage  🐳

##### Docker Compose:

```yaml
services:
  munin:
    image: dockurr/munin
    container_name: munin
    environment:
      TZ: "UTC"
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

##### Docker CLI:

```bash
docker run -it --rm --name munin -p 80:80 -e "NODES=node1:10.0.0.101 node2:10.0.0.102" --stop-timeout 60 docker.io/dockurr/munin
```

### Node configuration

Nodes can be configured using the `NODES` environment variable. Each node uses the format `name:address[:port]`, where `name` is a custom label used to identify the node in Munin and `address` is the hostname or IP address of the machine running `munin-node`.

For example:

```text
NODES="server:10.0.0.101 nas:10.0.0.102"
```

Multiple nodes can be separated by spaces or commas, so the following is equivalent:

```text
NODES="server:10.0.0.101,nas:10.0.0.102"
```

Munin uses port `4949` by default. A different port can be specified by adding it after the address:

```text
NODES="server:10.0.0.101:4950"
```

Existing configuration files in `/etc/munin/munin-conf.d` are left untouched. This means manually configured nodes, including nodes in an existing `nodes.conf`, are preserved and can be used alongside nodes supplied through the `NODES` environment variable.

For more advanced setups, additional Munin configuration can be placed directly in `/etc/munin/munin-conf.d`.

 # Acknowledgements 🙏
 
Special thanks to [@aheimsbakk](https://github.com/aheimsbakk), for creating the original project.

## Stars 🌟
[![Stargazers](https://raw.githubusercontent.com/star-stats/stars/refs/heads/data/charts/dockur-munin.svg)](https://github.com/dockur/munin/stargazers)

[build_url]: https://github.com/dockur/munin/
[hub_url]: https://hub.docker.com/r/dockurr/munin
[tag_url]: https://hub.docker.com/r/dockurr/munin/tags
[pkg_url]: https://github.com/dockur/munin/pkgs/container/munin

[Build]: https://github.com/dockur/munin/actions/workflows/build.yml/badge.svg
[Size]: https://img.shields.io/docker/image-size/dockurr/munin/latest?color=066da5&label=size
[Pulls]: https://img.shields.io/docker/pulls/dockurr/munin.svg?style=flat&label=pulls&logo=docker
[Version]: https://img.shields.io/docker/v/dockurr/munin/latest?arch=amd64&sort=semver&color=066da5
[Package]:https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fipitio.github.io%2Fbackage%2Fdockur%2Fmunin%2Fmunin.json&query=%24.downloads&logo=github&style=flat&color=066da5&label=pulls
