# Cron jobs

Cron runs inside the `cron` container, no host crontab involved.

## File layout

```
config/cron/
├── crontab              → crontab entries with time params (mounted into container)
├── projects/            → per-project backup settings (mounted at /etc/cron/projects/)
│   └── <project-name>.env
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

`data/config/cron/projects/<project-name>.env`:

```bash
DB_NAME=<db-name>
RETENTION_DAYS=7
CONFIG_PATHS=".env ./config/"
```

| Key              | Description                                                                                  |
|------------------|----------------------------------------------------------------------------------------------|
| `DB_NAME`        | Database name to dump                                                                        |
| `RETENTION_DAYS` | Delete backups older than N days                                                             |
| `CONFIG_PATHS`   | Space-separated paths relative to `/var/www/<project-name>`, archived into `config_*.tar.gz` |

### 2. Add a crontab entry

In `data/config/cron/crontab` (or `config/cron/crontab`):

```cron
# <Project>: DB + config backup (daily at 3:00 AM)
22 03 * * *   dump-project <project-name> 2>&1
```

The first argument is the project name — matches the `.env` filename and
the `/var/www/<project-name>` directory.

## Backup directory

Backups stored in `data/backup/<project-name>/`
