# Cron jobs

Cron runs inside the `cron` container, no host crontab involved.

## File layout

```
config/cron/
├── crontab              → crontab entries with time params (mounted into container)
├── projects/            → per-project backup settings (mounted at /etc/cron/projects/)
│   └── <config-name>    → no extension; PROJECT inside points to the project dir
└── README.md
```

## Adding a new project for backup

All projects live in `HOSTS_DATA` that is mapped to `/var/www/<project-name>` within containers: php, worker, cron.

> Any configuration changes made by the user should not be placed in files under Git control.

So if you need to modify backup settings or add any new projects put it all in a custom 'data/' directory defined in the ENV.
For example:

`CRON_CONFIG=./data/config/cron/crontab
CRON_DUMP_PROJECTS=./config/cron/projects/`

### 1. Create/modify a project dump config

`data/config/cron/projects/<config-name>` (no file extension):

```bash
PROJECT=<project-name>
DB_NAME=<db-name>
DB_ENGINE=pgsql
RETENTION_DAYS=7
CONFIG_PATHS=".env ./config/"
```

| Key              | Description                                                                                  |
|------------------|----------------------------------------------------------------------------------------------|
| `PROJECT`        | Project directory name — data is read from `/var/www/<PROJECT>`, backups go to `/var/backup/<PROJECT>`; required |
| `DB_NAME`        | Database name or space-separated list to dump; empty = config files only                     |
| `DB_ENGINE`      | `mysql` (default) or `pgsql` — which server to dump from (`db` vs `pg`)                      |
| `RETENTION_DAYS` | Delete backups older than N days                                                             |
| `CONFIG_PATHS`   | Space-separated paths relative to `/var/www/<PROJECT>`, archived into `config_*.tar.gz`      |

### 2. Add a crontab entry

In `data/config/cron/crontab` (or `config/cron/crontab`):

```cron
# <Project>: DB + config backup (daily at 3:00 AM)
22 03 * * *   dump-project <config-name> 2>&1
```

The argument is the config file name under `/etc/cron/projects/` — the project
directory is taken from `PROJECT` in that file, not from the filename.

## Backup directory

Backups stored in `data/backup/<PROJECT>/`
