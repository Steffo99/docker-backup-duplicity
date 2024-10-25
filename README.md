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

1. Create a new directory somewhere on your system to use to store certain configuration files; it can be anywhere, but for the purposes of this guide, it'll be referred to as `$ga_config_dir`, and will be located in `/srv/docker/.ga`:

    ```bash
    export ga_config_dir="/srv/docker/.ga"
    mkdir --verbose --parents "$ga_config_dir"
    ```

1. Create a new file inside `$ga_config_dir` secret with the name `ga_passphrase.txt`, which will contain the password used to encrypt backups before uploading them to Google Drive:

    ```bash
    cat "/dev/urandom" | LC_ALL="C" tr --delete --complement '[:graph:]' | head --bytes 32 > "$ga_config_dir/ga_passphrase.txt"
    ```

1. [Use the Google Cloud Console to create new OAuth credentials](https://console.cloud.google.com/apis/credentials) for a ***Desktop Application***.

1. Download the resulting JSON credential file, and move it inside `$ga_config_dir` with the name `ga_gdrive_client_secret.json`:

    ```bash
    mv --verbose --interactive ./client_secret* "$ga_config_dir/ga_gdrive_client_secret.json"

1. Create a new Docker volume with the name `ga_cache`, which will be used to temporarily store previous backups:

    ```bash
    docker volume create "ga_cache"
    ```

1. Create a new Docker volume with the name `ga_credentials`, which will be use to store Google Drive API credentials:

    ```bash
    docker volume create "ga_credentials"
    ```

1. Create a new directory in Google Drive, open it, and copy the final part of the URL:

    ```text
    https://drive.google.com/drive/u/0/folders/1_AAAAAAAAAA-BBBBBBBBBBBBBBBBBBBB
                                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                                         copy this part         
    ```

1. Add your Gestalt Amadeus configuration at the top of your `compose.yml` project:

    ```yaml
    x-gestalt-amadeus:
        # Set this to "restore" to recover files from the last available backup.
        x-ga-mode: &ga_mode
            "backup"
        # The URL where your backups should be uploaded to.
        # For Google Drive, replace:
        # - `1_AAAAAAAAAA-BBBBBBBBBBBBBBBBBBBB` with the final part of the URL you've previously copied
        # - `111111111111-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.apps.googleusercontent.com` with the value of the `.installed.client_id` key of the Google client_secret file you've previously downloaded
        x-ga-backup-to: &ga_backup_to
            "gdrive://111111111111-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.apps.googleusercontent.com/${COMPOSE_PROJECT_NAME}?myDriveFolderID=1_AAAAAAAAAA-BBBBBBBBBBBBBBBBBBBB"
        # If you're planning to use ntfy, set this to the full URL of the topic you'd like to receive notifications at.
        # If you don't want to use ntfy, set this to an empty string, "".
        x-ga-ntfy: &ga_ntfy
            "https://ntfy.sh/phil_alerts"
        # The path to the `ga_passphrase.txt` file.
        x-ga-passphrase: &ga_passphrase
            "/srv/docker/.ga/ga_passphrase.txt"
        # The path to the `ga_gdrive_client_secret.json` file.
        x-ga-gdrive-client-secret: &ga_gdrive_client_secret
            "/srv/docker/.ga/ga_gdrive_client_secret.json"
    ```

1. Merge the following keys with the rest of your existent `compose.yml` project:

    ```yaml
    services:
        ga:
            image: "ghcr.io/steffo99/gestalt-amadeus:2"
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
                NTFY_TAGS: "host-${HOSTNAME:-${hostname:-undefined}},${COMPOSE_PROJECT_NAME}"
                DUPLICITY_PASSPHRASE_FILE: "/run/secrets/ga_passphrase"
                GOOGLE_CLIENT_SECRET_JSON_FILE: "/run/secrets/ga_gdrive_client_secret"
                GOOGLE_CREDENTIALS_FILE: "/var/lib/duplicity/google_credentials"
                GOOGLE_OAUTH_LOCAL_SERVER_HOST: "localhost"
                GOOGLE_OAUTH_LOCAL_SERVER_PORT: "8080"
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
            file: *ga_passphrase
        ga_gdrive_client_secret:
            file: *ga_gdrive_client_secret
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

    > For authentication to work correctly after [Google's removal of the OOB Flow](https://developers.google.com/identity/protocols/oauth2/resources/oob-migration), your `http://localhost:8080` address needs to match the `http://localhost:8080` of the Gestalt Amadeus container.
    > 
    > This is not an issue if you can launch a browser on the same machine you're configuring Gestalt Amadeus, but it might be troublesome for non-graphical servers, where this is not possible.
    >
    > To apply a quick band-aid to the issue, you can temporarily set up an SSH tunnel towards the server for the duration of the setup process:
    >
    > ```bash
    > ssh -L 8080:8080 yourserver
    > ```

1. You should be done! Make sure backups are appearing in the Google Drive directory you've configured.
