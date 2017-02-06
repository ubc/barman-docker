#!/bin/bash

set -eo pipefail
shopt -s nullglob

echo "Setting ownership/permissions on ${BARMAN_DATA_DIR} and ${BARMAN_LOG_DIR}"
install -d -m 0700 -o barman -g barman ${BARMAN_DATA_DIR}
install -d -m 0755 -o barman -g barman ${BARMAN_LOG_DIR}

echo "Copying files from ${BARMAN_SSH_KEY_DIR} to ~barman/.ssh..."
for i in ${BARMAN_SSH_KEY_DIR}/*; do
	echo " ---> $(basename ${i})"
	install -m 0600 -o barman -g barman ${i} ~barman/.ssh/
done

if [[ -f ${BARMAN_PGPASSFILE} ]]; then
	echo "Copying ${BARMAN_PGPASSFILE} to ~barman/.pgpass"
	install -m 0600 -o barman -g barman ${BARMAN_PGPASSFILE} ~barman/.pgpass
fi

exec "$@"
