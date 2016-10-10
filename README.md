# Dockerfile for sysrepo-netopeer2 setup

To run `sysrepod` and `netopeer2-server` use the command:
```
docker run -i -t --name sysrepo --rm sysrepo/sysrepo-netopeer2:latest
```
You can connect to it via [testconf](https://hub.docker.com/r/sysrepo/testconf/) with the command:
```
docker run -i -t --link sysrepo --rm sysrepo/testconf:latest
```

or via SSH to port `6001` (username / password is `netconf`):
```
docker inspect sysrepo | grep -w "IPAddress"
# assuming output of the above commnd to be 172.17.0.3
ssh netconf@172.17.0.3 -p 6001 -s netconf 
```

[![demo](https://asciinema.org/a/05cdmz78fhcl5jeo4xyiqqr33.png)](https://asciinema.org/a/05cdmz78fhcl5jeo4xyiqqr33?autoplay=1)
