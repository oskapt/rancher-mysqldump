This is a container designed to safely dump MySQL to a K8s PersistentVolume, using a Secret and running as a CronJob.

## Prerequisites

1. This expects that you have a working Kubernetes installation. Rancher is not required, but it does make Kubernetes easier to use.
2. Create a user account in MySQL with the ability to back up the databases. This user only needs `SELECT` and `LOCK TABLES` globally.

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

  - DB_PASS - password to use when connecting (required)
  - DB_USER - username to connect as (required)
  - DB_HOST - host to connect to (required)
  - OUTPUT_DIR - where to write the dump output [/dump]
  - OUTPUT_FILENAME - what to save the dump as [dump.$(date '+%Y%M%d.%H%m').sql]
  - FILE_PER_DB - write out one file per database [0]
  - DATABASES - space-separated list of databases to back up
  - LOG_LEVEL - output level from 0 to 7 [6]

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

For this scenario, we'll be creating a CronJob that backs up a MySQL database to a mounted NFS volume. The volume will be mounted on `/dump` and will use a static PersistentVolume called `prod-db-dump`.

1. Create a namespace called `backup`. If you're using Rancher, you may wish to add this to a specific project. You can do so via the Rancher CLI or the GUI.

    ``` bash
    $ # using the rancher CLI
    $ rancher namespace create backup
    $ # or, using regular kubectl (if not using Rancher)
    $ kubectl create ns backup
    namespace/backup created
    ```

2. Create a secret to store the database password for the backup user. We'll call this `prod-db-backup-password`. If you have different database servers that you'll be backing up, it helps to identify which server the password is for. Even if you're using the same password for the user on each system, create different secrets. They're different user accounts, even if they have the same name.

    ``` bash
    $ # use a secure means to paste a password into a file called DB_PASS
    $ # like pbpaste on MacOS
    $ pbpaste > ./DB_PASS
    $ kubectl -n backup create secret generic prod-db-backup-password --from-file=./DB_PASS
    secret/prod-db-backup-password created
    $ # if you don't have srm, use rm instead
    $ srm DB_PASS
    ```

3. Create the PersistentVolume and PersistentVolumeClaim

    ``` bash
    $ kubectl apply -f k8s/pv.yaml
    persistentvolume/prod-db-dump created
    $ kc apply -f k8s/pvc.yaml
    persistentvolumeclaim/prod-db-dump created
    ```

4. Edit `k8s/cronjob.yaml` and apply it to create a CronJob called `mysqldump-prod`. This job will run at the interval you set in the YAML. Set the `DB_USER` and `DB_HOST` environment variables and add any others that you wish to have control the job.

    ``` bash
    $ kubectl apply -f k8s/cronjob.yaml
    ```

The CronJob will run the container as a job using the schedule you specified. By default it will keep the last 10 containers. You can view log output in the container logs.
