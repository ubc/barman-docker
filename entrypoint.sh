#!/bin/bash

echo "Setting ownership/permissions on ${BARMAN_DATA_DIR} and ${BARMAN_LOG_DIR}"

install -d -m 0700 -o barman -g barman ${BARMAN_DATA_DIR}
install -d -m 0755 -o barman -g barman ${BARMAN_LOG_DIR}

echo "Generating cron schedules"
echo "${BARMAN_CRON_SCHEDULE} barman /usr/local/bin/barman receive-wal --create-slot ${DB_HOST}; /usr/local/bin/barman cron" >> /etc/cron.d/barman
echo "${BARMAN_BACKUP_SCHEDULE} barman /usr/local/bin/barman backup all" >> /etc/cron.d/barman

echo "Generating Barman configurations"
cat /etc/barman.conf.template | envsubst > /etc/barman.conf
cat /etc/barman/barman.d/pg.conf.template | envsubst > /etc/barman/barman.d/${DB_HOST}.conf
echo "${DB_HOST}:${DB_PORT}:*:${DB_SUPERUSER}:${DB_SUPERUSER_PASSWORD}" > /home/barman/.pgpass
echo "${DB_HOST}:${DB_PORT}:*:${DB_REPLICATION_USER}:${DB_REPLICATION_PASSWORD}" >> /home/barman/.pgpass
chown barman:barman /home/barman/.pgpass
chmod 600 /home/barman/.pgpass

echo "Checking/Creating replication slot"
barman replication-status ${DB_HOST} --minimal --target=wal-streamer | grep barman || barman receive-wal --create-slot ${DB_HOST}
barman replication-status ${DB_HOST} --minimal --target=wal-streamer | grep barman || barman receive-wal --reset ${DB_HOST}

if [[ -f /home/barman/.ssh/id_rsa ]]; then
    echo "Setting up Barman private key"
    chmod 700 ~barman/.ssh
    chown barman:barman -R ~barman/.ssh
    chmod 600 ~barman/.ssh/id_rsa
fi

echo "Initializing done"

# run barman exporter every hour
exec /usr/local/bin/barman-exporter -l ${BARMAN_EXPORTER_LISTEN_ADDRESS}:${BARMAN_EXPORTER_LISTEN_PORT} -c ${BARMAN_EXPORTER_CACHE_TIME} &
echo "Started Barman exporter on ${BARMAN_EXPORTER_LISTEN_ADDRESS}:${BARMAN_EXPORTER_LISTEN_PORT}"

exec "$@"
