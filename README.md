# docker-backup-duplicity

Backup solution for Docker volumes based on Duplicity

## Usage

> **Note**: The following instructions assume Google Drive is used as a storage backend; refer to [duplicity's man page](https://duplicity.us/stable/duplicity.1.html) to find out how to configure different backends!

1. Create a new volume in Docker with the name `duplicity_credentials`:

    ```console
    # docker volume create duplicity_credentials
    ```

2. Create a new file in the host system with the name `/root/secrets/backup/passphrase.txt`, and enter in it a secure passphrase to use to encrypt files:

    ```console
    # echo 'CorrectHorseBatteryStaple' >> /root/secrets/backup/passphrase.txt
    ```

3. [Obtain *Desktop Application* OAuth credentials from the Google Cloud Console.](https://console.cloud.google.com/apis/credentials)

4. Create a new file in the host system with the name `/root/secrets/backup/client_config.yml`, and enter the following content in it:

    ```console
    # edit /root/secrets/backup/client_config.yml
    ```

    ```yml
    client_config_backend: settings
    client_config:
        client_id: "YOUR_GOOGLE_CLIENT_ID_GOES_HERE"
        client_secret: "YOUR_GOOGLE_CLIENT_SECRET_GOES_HERE"
    save_credentials: True
    save_credentials_backend: file
    save_credentials_file: "/var/lib/duplicity/credentials"
    get_refresh_token: True
    ```

5. Add the following keys to the `docker-compose.yml` file of the project you want to backup:

    ```console
    # edit ./docker-compose.yml
    ```

    1. If you haven't already, upgrade your `docker-compose.yml` file to version 3.9:

        ```yml
        version: "3.9"
        ```

    2. Connect the previously created `duplicity_credentials` volume to the project:

        ```yml
        volumes:
            duplicity_credentials:
                external: true
        ```

    3. Setup the two previously created files as Docker secrets:

        ```yml
        secrets:
            duplicity_passphrase:
                file: "/root/secrets/backup/passphrase.txt"
            google_client_config:
                file: "/root/secrets/backup/client_config.yml"
        ```

    4. Add the following service:

        ```yml
        services:
            backup:
                image: "ghcr.io/steffo99/backup-duplicity:latest"
                restart: unless-stopped
                secrets:
                    - google_client_config
                    - duplicity_passphrase
                volumes:
                    - "duplicity_credentials:/var/lib/duplicity" 
                    # Mount whatever you want to backup in subdirectories of /mnt
                    - ".:/mnt/compose"  # Backup the current directory?
                    - "data:/mnt/data"  # Backup a named volume?
                environment:
                    MODE: "backup"  # Change this to "restore" to restore the latest backup
                    DUPLICITY_TARGET_URL: "pydrive://YOUR_GOOGLE_CLIENT_ID_GOES_HERE/Duplicity/this"  # Change this to the Drive directory you want to backup files to https://man.archlinux.org/man/duplicity.1.en#URL_FORMAT
                    # Don't touch these, they allow the program to read the secrets
                    DUPLICITY_PASSPHRASE_FILE: "/run/secrets/duplicity_passphrase"
                    GOOGLE_DRIVE_SETTINGS: "/run/secrets/google_client_config"
        ```

6. Log in to Google Drive and perform an initial backup with:

    ```console
    # docker compose run -i backup --entrypoint=/bin/sh /etc/periodic/daily/backup.sh
    ```

7. Properly start the container with:

    ```console
    # docker compose up -d && docker compose logs -f
    ```