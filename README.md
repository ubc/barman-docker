# docker-barman

This repo contains files used to build a [docker](https://www.docker.com) image
for running [BaRMan](https://github.com/2ndquadrant-it/barman), the "Backup and
Recovery Manager for PostgreSQL."

It is easily used in conjunction with the `tbeadle/postgres:<version>-barman`
images at https://hub.docker.com/r/tbeadle/postgres/.

Rapyuta-chart : [Barman-chart](https://github.com/rapyuta-robotics/rapyuta-charts/tree/devel/incubator/barman)

Rapyuta-chart documentation: [Barman-chart documentation](https://github.com/rapyuta-robotics/rapyuta-charts/tree/devel/incubator/barman)


## Getting the image

`docker-compose pull`

## Building the image

If you would like to build the image yourself, simply run:

`docker compose build barman`

## Running the image

Running the image can be as simple as

`docker compose up barman`

Note: Barman requires postgresql to be up and running

but you will likely want to create your own `docker-compose.yml` file to define
volumes that will be mounted for persistent data.  See the ***Environment
variables*** section below.

The barman program is run inside the container as the `barman` user.  If you
enter a shell in the container and want to run barman commands, make sure to run
them as the `barman` user using `gosu barman <barman command>`.  For example:

```bash
docker exec -it barman /bin/bash
```

```bash
gosu barman barman check all
gosu barman barman backup all
```

## Examples of usage

See the examples/ directory for examples of how to use this image.

 * ***streaming***: The remote database server streams its WAL logs to barman.
   This reduces the "Recovery Point Objective (RPO)" to nearly 0.  RPO is the
   "maximum amount of data you can afford to lose."<sup>[1](#barman_docs)</sup>
   This example also sets up  a weekly cron job to take incremental base backups
   using rsync.  This helps reduce the time that would be required to play back
   the WAL files in a disaster recovery situation.

Currently only streaming of WAL logs is supported.  Using postgres's
`archive_command` functionality is not supported at this time.

## Environment variables

The following environment variables may be set when starting the container:

| Name                               | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ----                               | -----------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| BARMAN_CRON_SRC                    | This directory holds files that will be copied in to `/etc/cron.d/` and have the correct permissions set so that they will be run via cron.  This can be used as a place to put cron jobs for performing regular basebackups.  Defaults to `/private/cron.d`.
| BARMAN_LOG_DIR                     | The location where log files can be stored.  For example, a cron job can be set up to take regular full backups and that can send its logs here.  Defaults to `/var/log/barman`.                                                                                                                                                                                                                                                                                                                                                                        |
| BARMAN_SSH_KEY_DIR                 | This directory in the container (most likely mounted as a volume) should contain SSH private key files that are used when connecting via SSH to the database servers that you're backing up.  This happens if the `backup_method` defined in the barman config for the server is set to `rsync`.  The `ssh_command` for that server should include `-i /home/barman/.ssh/<private_key_filename>`.  Note that the keys are copied from this directory to /home/barman/.ssh/ to ensure ownership/permissions are properly set.  Defaults to /private/ssh. |
| BARMAN_CRON_SCHEDULE               | `* * * * *`, barman cron running scheduel
| BARMAN_BACKUP_SCHEDULE             | `0 4 * * *`, barman backup running schedule
| BARMAN_LOG_LEVEL                   | `INFO`, barman log level
| DB_HOST                            | `pg`, postgres host name
| DB_PORT                            | `5432`, postgres port
| DB_SUPERUSER                       | `postgres`, superuser username
| DB_SUPERUSER_PASSWORD              | `postgres`, superuser password
| DB_SUPERUSER_DATABASE              | `postgres`, superuser database
| DB_REPLICATION_USER                | `standby`, replication username
| DB_REPLICATION_PASSWORD            | `standby`, replication user password
| DB_SLOT_NAME                       | `barman`, postgres replication slot name for barman
| DB_BACKUP_METHOD                   | `postgres`, barman backup method, see barman backup

## Volumes

| Path                     | Description                                                                      |
|--------------------------|----------------------------------------------------------------------------------|
| /home/barman/.ssh/id_rsa | The private ssh key that barman will use to connect to remote host when recovery |

## Footnotes:

<a name='barman_docs'><sup>1</sup></a>: [Barman Documentation](http://docs.pgbarman.org/release/2.1/)
