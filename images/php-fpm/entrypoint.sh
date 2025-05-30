#!/bin/bash
set -e

echo "uid-gid: $UID:${GID}\n"
getent group ${GID} || groupadd --gid ${GID} g${GID}
getent passwd ${UID} || useradd --shell /bin/bash --uid ${UID} --gid ${GID} -m u${UID}

/sbin/my_init
