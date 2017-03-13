#!/bin/bash

set -eo pipefail
shopt -s nullglob

echo "Copying files from ${BARMAN_SSH_KEY_DIR} to ~barman/.ssh..."
for i in ${BARMAN_SSH_KEY_DIR}/*; do
	echo " ---> $(basename ${i})"
	install -m 0600 -o barman -g barman ${i} ~barman/.ssh/
done

if [[ -f ${BARMAN_PGPASSFILE} ]]; then
	echo "Copying ${BARMAN_PGPASSFILE} to ~barman/.pgpass"
	install -m 0600 -o barman -g barman ${BARMAN_PGPASSFILE} ~barman/.pgpass
fi

for i in ${BARMAN_CRON_SRC}/*; do
	echo "Installing ${i} in /etc/cron.d/"
	install -m 0644 -o root -g root ${i} /etc/cron.d/
done
