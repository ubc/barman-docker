#!/bin/bash

set -exo pipefail
shopt -s nullglob

# Install barman
# Create a 'barman' user that it will run as.
# Create a .ssh directory for the 'barman' user.  SSH keys will be used to rsync
#     basebackups from the database servers.
# Install the barman cron job that ensures that pg_receivexlog is running for
#     all of the database servers set to stream its WAL logs.
wget -O - https://bootstrap.pypa.io/get-pip.py | python -
# Requests isn't actually necessary, but it can be useful for barman hook scripts
# for notification of the backup status.
pip install barman==${BARMAN_VERSION} requests==2.13.0
useradd --system --shell /bin/bash barman
install -d -m 0700 -o barman -g barman ~barman/.ssh
gosu barman bash -c 'echo -e "Host *\n\tCheckHostIP no" > ~/.ssh/config'
cat >/etc/crontab <<EOF
* * * * * barman /usr/local/bin/barman -q cron
@daily root /usr/sbin/logrotate /etc/logrotate.conf
EOF
rm /etc/logrotate.d/*
cat >/etc/logrotate.conf <<EOF
${BARMAN_LOG_DIR}/*.log {
	weekly
	rotate 4
	delaycompress
	compress
	missingok
	notifempty
	create 0640 barman barman
}
EOF
install -d -m 0755 -o barman -g barman ${BARMAN_LOG_DIR}
