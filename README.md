# docker-barman

This repo contains files used to build a [docker](https://www.docker.com) image
for running [BaRMan](https://github.com/2ndquadrant-it/barman), the "Backup and
Recovery Manager for PostgreSQL."

It is easily used in conjunction with the `tbeadle/postgres:<version>-barman`
images at https://hub.docker.com/r/tbeadle/postgres/.

## Getting the image

`docker-compose pull`

## Building the image

If you would like to build the image yourself, simply run:

`docker-compose build`

## Running the image

Running the image can be as simple as

`docker-compose up`

but you will likely want to create your own `docker-compose.yml` file to define
volumes that will be mounted for persistent data.  See the ***Environment
variables*** section below.

The barman program is run inside the container as the `barman` user.  If you
enter a shell in the container and want to run barman commands, make sure to run
them as the `barman` user using `gosu barman <barman command>`.  For example:

```
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

| Name | Description |
| ---- | ----------- |
| BARMAN_CRON_SRC | This directory holds files that will be copied in to `/etc/cron.d/` and have the correct permissions set so that they will be run via cron.  This can be used as a place to put cron jobs for performing regular basebackups.  Defaults to `/private/cron.d`.
| BARMAN_DATA_DIR | The location in the container where barman stores the data backed up from the databases.  This should likely be mounted as a volume so that the data persists after the container is stopped or destroyed.  It should also be set as the `barman_home` configuration value in `barman.conf`.  Defaults to `/var/lib/barman`. |
| BARMAN_LOG_DIR | The location where log files can be stored.  For example, a cron job can be set up to take regular full backups and that can send its logs here.  Defaults to `/var/log/barman`. |
| BARMAN_SSH_KEY_DIR | This directory in the container (most likely mounted as a volume) should contain SSH private key files that are used when connecting via SSH to the database servers that you're backing up.  This happens if the `backup_method` defined in the barman config for the server is set to `rsync`.  The `ssh_command` for that server should include `-i /home/barman/.ssh/<private_key_filename>`.  Note that the keys are copied from this directory to /home/barman/.ssh/ to ensure ownership/permissions are properly set.  Defaults to /private/ssh. |
| BARMAN_PGPASSFILE | The path to a file in the container that is a [pgpass](https://www.postgresql.org/docs/9.6/static/libpq-pgpass.html) file containing the passwords for the users used when connecting to the database servers.  The users are defined by the `conninfo` and `streaming_conninfo` configuration variables for the servers.  This file is copied to `/home/barman/.pgpass` when the container is started.  Defaults to `/private/pgpass`. |

## Notes

If using a replication slot for a server, the slot must be created before streaming replication can start.  If using a `tbeadle/postgres:*-barman` image, this is done automatically for you if the `BARMAN_SLOT_NAME` variable is set, which defaults to `barman`.  If not using that image for your database, you can create the slot from the barman server by running the following command in the container:

```
gosu barman barman receive-wal --create-slot <name of server in barman config>
```

The next time `barman cron` runs (which runs every minute), replication will
start.  In order to take a base backup (using `gosu barman barman backup all`),
the database needs to have had a transaction.  Once there has been a
transaction, you can run `gosu barman barman switch-xlog --force <name of
server>` and then wait for `barman cron` to run again (or run it manually).
Then you can run `gosu barman barman check <name of server>` to confirm that
all checks are OK.  Then you can run `gosu barman barman backup <name of
server>`.

## Footnotes:

<a name='barman_docs'><sup>1</sup></a>: [Barman Documentation](http://docs.pgbarman.org/release/2.1/)
