#!/bin/bash
set -e

echo "gid: $GID ${GID}"
getent group ${GID} || (groupadd --gid ${GID} g${GID} && useradd --shell /bin/bash --uid ${UID} --gid ${GID} -m u${UID})

/sbin/my_init
