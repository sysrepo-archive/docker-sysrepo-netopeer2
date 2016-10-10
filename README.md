# Dockerfile for sysrepo-netopeer2 setup

To run sysrepod and netopeer2-server use the command:
```
docker run -i -t --name sysrepo --rm sysrepo/sysrepo-netopeer2:latest
```
You can connect to it via [testconf](https://hub.docker.com/r/sysrepo/testconf/) with the command:
```
docker run -i -t --link sysrepo --rm sysrepo/testconf:latest
```

[![demo](https://asciinema.org/a/05cdmz78fhcl5jeo4xyiqqr33.png)](https://asciinema.org/a/05cdmz78fhcl5jeo4xyiqqr33?autoplay=1)
