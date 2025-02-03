# Icinga2 Satellite Setup Script

## Overview
This script automates the setup and configuration of an Icinga2 Satellite Node on Ubuntu. It performs installation, certificate generation, parent node verification, API setup, and node configuration in a structured manner.

## Features
- Automatically detects Ubuntu version
- Installs necessary packages and adds Icinga2 repository
- Allows user to choose the Icinga2 version
- Sets up Icinga2 certificates and verifies parent connection
- Configures Icinga2 API and Node setup
- Creates API users with full permissions
- Adds Nagios check_mem.pl plugin to the directory
- Restarts and verifies the Icinga2 service status

## Prerequisites
Ensure that you have:
- Ubuntu installed on the machine
- Sudo privileges
- Network connectivity to the Icinga2 master

## Installation
1. Clone this repository:
   ```sh
   git clone https://github.com/yourusername/icinga2-satellite-setup.git
   cd icinga2-satellite-setup

2. Make the script executable:
   ```sh
   chmod +x setup_icinga2.sh

3. Run the script:
   ```sh
   sudo ./setup_icinga2.sh

## Configuration
Modify the following variables in the script as per your environment:
```sh
MASTER_HOSTNAME="MasterHostname"
MASTER_IP_FQDN="MasterIP or FQDN"
TICKET="c9ad4df64226700e8401f1236e3cdcd5d44d18a7"
LOCAL_ZONE_NAME="XXSUPSAT01"
API_USERNAME="XXSUPSAT01"
API_PASSWORD="Password"
```

## Troubleshooting
- If the script fails at a step, check the logs in /var/log/icinga2/icinga2.log.
- Verify network connectivity to the Icinga2 master (ping <master-IP>).
- Ensure the necessary ports (5665) are open.

## License
- This project is licensed under the MIT License - see the LICENSE file for details.

## Author
- Created by Prathamesh. Feel free to contribute or report issues!

