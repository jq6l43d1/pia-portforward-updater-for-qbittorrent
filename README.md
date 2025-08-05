# qBittorrent Port Forwarding Automation Script

This script automates the process of updating the qBittorrent listening port with the port forwarded by Private Internet Access (PIA). It is designed to be run on a schedule, ensuring that your qBittorrent client is always reachable through the PIA VPN, even when the forwarded port changes.

## Description

The script performs the following actions:
1.  Retrieves the currently forwarded port from the PIA client using `piactl`.
2.  If it fails to get a valid port, it will attempt to disconnect and reconnect the PIA client to obtain a new port.
3.  It validates the retrieved port to ensure it's a valid number.
4.  Updates the `listen_port` in your qBittorrent client's settings via its Web UI.
5.  Logs its actions and any errors to syslog for easy monitoring and troubleshooting.

## Prerequisites

Before using this script, you must have the following software installed:

*   **Private Internet Access (PIA) client:** The script relies on the `piactl` command-line tool that comes with the official PIA client.
*   **qBittorrent:** The qBittorrent client must be running with the Web UI enabled.
*   **qBittorrent CLI:** This script uses `qbt`, a command-line interface for qBittorrent, to update the port. You can find installation instructions for it on its GitHub page.

## Configuration

You will need to edit the script to match your specific setup. The following variables at the top of the script may need to be changed:

*   `QBT_URL`: The full URL to your qBittorrent Web UI. The default is `http://localhost:8888/`.
*   `PIACTL_CMD`: The full path to the `piactl` command. You can find this by running `which piactl`.
*   `QBT_CMD`: The full path to the `qbt` command. You can find this by running `which qbt`.
*   `LOGGER_CMD`: The full path to the `logger` command. You can find this by running `which logger`.

## Installation and Scheduling with Cron

To have this script run automatically at a set interval, you can add it to your user's crontab.

1.  **Make the script executable:**
    ```bash
    chmod +x /path/to/your/qbt-pia-port-sync.sh
    ```

2.  **Edit your crontab:**
    Open your user's crontab file for editing by running the following command. If it's your first time, you may be prompted to choose a text editor.
    ```bash
    crontab -e
    ```

3.  **Add the cron job:**
    Add a new line to the end of the file to schedule the script. The following example will run the script every 15 minutes. Make sure to replace `/path/to/your/qbt-pia-port-sync.sh` with the actual path to the script.

    ```
    */15 * * * * /path/to/your/qbt-pia-port-sync.sh
    ```

    Here's a breakdown of the cron syntax:
    *   `*/15`:  Every 15 minutes
    *   `*`: Every hour
    *   `*`: Every day of the month
    *   `*`: Every month
    *   `*`: Every day of the week

4.  **Save and exit the editor.** Your new cron job is now active.

## Logging

The script logs its progress and any errors to `syslog`. This is helpful for debugging any issues that may arise. On most Linux systems, you can view these logs by checking the system's main log file (e.g., `/var/log/syslog` or `/var/log/messages`) or by using the `journalctl` command.

To view the logs specifically for this script, you can use a command like:
```bash
grep "qbt-pia-port-sync.sh" /var/log/syslog
```
or
```bash
journalctl -t qbt-pia-port-sync.sh
```Replace `qbt-pia-port-sync.sh` with the actual name of your script file.