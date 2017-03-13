FROM debian:jessie

# Install gosu
ENV GOSU_VERSION=1.9

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates wget \
	&& dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& rm -rf /var/lib/apt/lists/*

# Install postgres 9.4, 9.5, 9.6 clients.  This is so that barman can use the
# appropriate version when using pg_basebackup.
# Install some other requirements as well.
#   cron: For scheduling base backups
#   gcc: For building psycopg2
#   libpq-dev: Needed to build/run psycopg2
#   libpython-dev: For building psycopg2
#   logrotate: For rotating barman log files
#   openssh-client: Needed to rsync basebackups from the database servers
#   python: Needed to run barman
#   rsync: Needed to rsync basebackups from the database servers
RUN bash -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" >> /etc/apt/sources.list.d/pgdg.list' \
	&& (wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -) \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		cron \
		gcc \
		libpq-dev \
		libpython-dev \
		logrotate \
		openssh-client \
		postgresql-client-9.4 \
		postgresql-client-9.5 \
		postgresql-client-9.6 \
		python \
		rsync \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -f /etc/crontab /etc/cron.*/* \
	&& sed -i 's/\(.*pam_loginuid.so\)/#\1/' /etc/pam.d/cron

# Set up some defaults for file/directory locations used in entrypoint.sh.
ENV \
	BARMAN_VERSION=2.1 \
	BARMAN_CRON_SRC=/private/cron.d \
	BARMAN_DATA_DIR=/var/lib/barman \
	BARMAN_LOG_DIR=/var/log/barman \
	BARMAN_SSH_KEY_DIR=/private/ssh \
	BARMAN_PGPASSFILE=/private/pgpass
VOLUME /var/log/barman

COPY install_barman.sh /tmp/
RUN /tmp/install_barman.sh && rm /tmp/install_barman.sh

# Install the entrypoint script.  It will set up ssh-related things and then run
# the CMD which, by default, starts cron.  The 'barman -q cron' job will get
# pg_receivexlog running.  Cron may also have jobs installed to run
# 'barman backup' periodically.
ENTRYPOINT ["/entrypoint.sh"]
CMD ["cron", "-L", "0",  "-f"]
COPY entrypoint.sh /
COPY update_secure_files /usr/bin/
WORKDIR ${BARMAN_DATA_DIR}
