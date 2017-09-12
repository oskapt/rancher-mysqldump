This is a container designed to safely dump MySQL, utilizing Rancher Secrets and Rancher Container Cron.

## Prerequisites

1. This expects that you have a working Rancher installation, using Cattle as an orchestrator
2. Install Rancher Secrets
3. Install Rancher Container Cron
4. Create a user account in MySQL with the ability to back up the databases. This user only needs `SELECT` and `LOCK TABLES` globally.

## Usage
```
 Help using ./mysqldump

  -v               Enable verbose mode, print script as it is executed
  -d --debug       Enables debug mode
  -h --help        This page
  -n --no-color    Disable color output
  -z --dry-run     Print what would happen but don't do anything

 This script will incorporate environment variables and Rancher Secrets
 into a mysqldump command. It will use the following variables, with
 defaults specified where appropriate:

  - SECRET_FILE - where in /run/secrets to find the database password [db_pass]
  - DB_USER - username to connect as (required)
  - DB_HOST - host to connect to (required)
  - OUTPUT_DIR - where to write the dump output [/dump]
  - OUTPUT_FILENAME - what to save the dump as [dump.$(date '+%Y%M%d.%H%m').sql]
  - FILE_PER_DB - write out one file per database [0]
  - DATABASES - space-separated list of databases to back up
  - LOG_LEVEL - output level from 0 to 7 [6]
  - SKIP_TIME - time in seconds to skip per-file backups that already exist [82800]

  If --user or --host are provided in the command line, they will be ignored
  if also set as environment variables.

  If you set FILE_PER_DB to 1, you need to provide DATABASES, and in this case you
  should _not_ specify any databases to back up on the command line. The databases will
  be named in the form of {name}.sql in the dump directory.

  If you wish to skip a database dump run entirely, you can touch .skip in the output
  directory, and the run will skip.
```

## Additional Features

- If you touch `.skip` in the output directory, backups will not run. 
- You can pass flags directly to `mysqldump` by setting following script flags with `--` and then providing flags for `mysqldump` (e.g. `-z -- --no-data`)

## Walkthrough

For this scenario, we'll be creating a container that backs up an RDS instance

1. Create a secret to store the database password for the backup user. We'll call this `prod_db_backup_password_v0`. If you have different database servers that you'll be backing up, it helps to identify which server the password is for. Even if you're using the same password for the user on each system, create different secrets. They're different user accounts, even if they have the same name.
2. Create a stack called `backup`
3. Create a service called `mysqldump-prod`
4. Under the _Command_ tab set the environment variables that you need, including, at the least:
    - `DB_USER`
    - `DB_HOST`
5. Also under the _Command_ tab, set _Console_ to `None` and _Auto Restart_ to `Never`
6. Under the _Volumes_ tab, mount some type of persistent storage at `/dump`. If you will be dumping multiple database servers and coming through later to ship them offsite, consider making this an NFS mount with Rancher NFS.
7. Under the _Secrets_ tab, mount `prod_db_backup_password_v0` as `db_pass`.
8. Under the _Labels_ tab, add a label of `cron.schedule` and set it to `@every 6h`. 
9. Add any additional scheduling or other configuration, and click _Launch_.

The container will start, execute the backup, and then stop. You can view log output in the container logs.

## Questions

#### Why is the default `82800` seconds instead of `86400`?

When the job runs, it takes some time for the dump to complete. Let's say that it takes 1 minute. If we have the job set to skip runs if the backup is less than 24 hours old, the backup will appear to be 86,340 seconds old, which is less than 86,400. The jobs will skip for 24h, and you'll end up with a backup every two days. Setting this to 82,800 allows your backups to take as much as an hour to run.

#### Why run the container every X hours instead of every 24 hours?

The container cron comes around at an interval from launch time. If you set it to `@every 24h` and you upgrade the container at 0915 in the morning, it'll start running backups every day at 0915. By setting it to scan every 6h (or 4h or 1h or 30m) you're assured that it will run within that interval of the backup expiring, giving you dumps that generally fall between midnight and 0600. You're welcome to change it to run at a specific time instead.


