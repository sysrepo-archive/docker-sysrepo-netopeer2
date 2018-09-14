#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

./generate_install_script.sh
docker build --no-cache -t sysrepo/sysrepo-netopeer2:snabb_master -f Dockerfile .
