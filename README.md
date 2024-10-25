<div align="center">

![](.media/icon-128x128_round.png)

# Gestalt Amadeus

Backup solution for Docker volumes based on Duplicity

</div>

## Usage

> [!NOTE]
>
> Other backends are available, but haven't been tested. Please let me know if you want to try using them so I can help you out with setting them up!

### Backup with Google Drive

1. Create a new Docker volume with the name `ga_cache`, which Duplicity will use to temporarily store previous backups:

    ```bash
    docker volume create "ga_cache"
    ```

1. Create a new Docker volume with the name `ga_credentials`, which Duplicity will use to store Google Drive API credentials:

    ```bash
    docker volume create "ga_credentials"
    ```

1. Create a new Docker secret with the name `ga_passphrase` containing the password that will be used to encrypt backups before uploading them:

    ```bash
    # This command will generate a secure random password, print it to the console, and use it to create a Docker secret 
    cat /dev/urandom | LC_ALL="C" tr --delete --complement '[:graph:]' | head --bytes 32 | tee "/dev/stderr" | docker secret create "ga_passphrase" -
    ```

1. [Use the Google Cloud Console to create new OAuth credentials](https://console.cloud.google.com/apis/credentials) for a ***Desktop Application***.

1. Download the JSON credential file, and use it to create a new Docker secret with the name `ga_gdrive_client_secret`:

    ```bash
    docker secret create "ga_gdrive_client_secret" ./client_secret*
    ```

1. Create a new directory in Google Drive, open it, and copy the final part of the URL:

    ```text
    https://drive.google.com/drive/u/0/folders/1_8rQ4E8ssoN-guFrGs7CC2IFofXBaimi
                                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                                         copy this part         
    ```

1. Add your Gestalt Amadeus configuration in your Compose project at `compose.yml`:
    ```yaml
    x-gestalt-automata:
        # Set this to "restore" to recover files from the last available backup.
        ga_mode: &ga_mode
            "backup"
        # The URL where your backups should be uploaded to.
        # For Google Drive, replace:
        # - `1_AAAAAAAAAA-BBBBBBBBBBBBBBBBBBBB` with the final part of the URL you've previously copied
        # - `111111111111-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.apps.googleusercontent.com` with the value of the `.installed.client_id` key of the Google client_secret file you've previously downloaded
        ga_backup_to: &ga_backup_to
            "gdrive://111111111111-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.apps.googleusercontent.com/${COMPOSE_PROJECT_NAME}?myDriveFolderID=1_AAAAAAAAAA-BBBBBBBBBBBBBBBBBBBB"
        # If you're planning to use ntfy, set this to the full URL of the topic you'd like to receive notifications at.
        # An example: `ntfy.sh/ko7OC50phzmh1ZMQ`
        ga_ntfy: &ntfy
            ""
    ```

1. Merge the following keys to your Compose project at `compose.yml`:

    ```yaml
    services:
        ga:
            image: ""
            restart: unless-stopped
            network_mode: host
            stdin_open: true
            tty: true
            volumes:
                - type: bind
                  source: "."
                  target: "/mnt"
                - type: volume
                  source: ga_credentials
                  target: "/var/lib/duplicity"
                - type: volume
                  source: ga_cache
                  target: "/usr/lib/duplicity/.cache/duplicity"
            environment:
                MODE: *ga_mode
                DUPLICITY_TARGET_URL: *ga_backup_to
                NTFY: *ga_ntfy
                NTFY_TAGS: "host-${HOSTNAME},${COMPOSE_PROJECT_NAME}"
                DUPLICITY_PASSPHRASE_FILE: "/run/secrets/ga_passphrase"
                GOOGLE_CLIENT_SECRET_JSON_FILE: "/run/secrets/ga_gdrive_client_secret"
                GOOGLE_CREDENTIALS_FILE: "/var/lib/duplicity/google_credentials"
                GOOGLE_OAUTH_LOCAL_SERVER_HOST: "localhost"
                GOOGLE_OAUTH_LOCAL_SERVER_PORT: "80"
            secrets:
                - ga_passphrase
                - ga_gdrive_client_secret
    
    volumes:
        ga_cache:
            external: true
        ga_credentials:
            external: true
    
    secrets:
        ga_passphrase:
            external: true
        ga_gdrive_client_secret:
            external: true
    ```

1. Bring up the Compose project:

    ```bash
    docker compose up --detach
    ```

1. Pay attention to the logs; if this is the first container you're setting up Gestalt Automata on the host, you'll be asked to login with Google before the backup can proceed:

    ```bash
    docker compose logs --follow ga
    ```

    ```log
    duplicity-1  | Please visit this URL to authorize this application: https://accounts.google.com/o/oauth2/auth
    ```

    Complete the authentication to proceed.

    (Make sure to read the alert below if you're having issues!)

1. You should be done! Make sure backups are appearing in the Google Drive directory you've configured.

> [!CAUTION]
> 
> For authentication to work correctly after [Google's removal of the OOB Flow](https://developers.google.com/identity/protocols/oauth2/resources/oob-migration), your `http://localhost:80` address needs to match the `http://localhost:80` of the Gestalt Amadeus container.
> 
> This is not an issue if you can launch a browser on the same machine you're configuring Gestalt Amadeus, but it might be troublesome for non-graphical servers, where this is not possible.
>
> To apply a quick band-aid to the issue, you can temporarily set up an SSH tunnel towards the server for the duration of the setup process:
>
> ```bash
> # This unfortunately requires root access, since the port we have to tunnel, 80, has a number lower than 1024.
> sudo ssh -L 80:80 yourserver
> ```