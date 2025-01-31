#!/bin/bash

# Exit script on any error
set -e

# Variables for Icinga2 setup
MASTER_HOSTNAME="MasterHostname"
MASTER_IP_FQDN="MasterIP or FQDN"
TICKET="c9ad4df64226700e81123fb276e3cdcd5d44d18a7"
LOCAL_ZONE_NAME="XXSUPSAT01"
UBUNTU_CODENAME=$(lsb_release -sc)  # Detect Ubuntu release codename dynamically
API_USERNAME="XXSUPSAT01"  # Using hostname as the API username (satellite server command name)
API_PASSWORD="Password"  # Define a password for the API user

# Color codes for output
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RED="\033[1;31m"
BLUE="\033[1;34m"
RESET="\033[0m"

echo -e "${YELLOW}📌 Starting Icinga2 setup on Ubuntu ${UBUNTU_CODENAME}...${RESET}\n"

# Step 1: Update and upgrade the Ubuntu instance
# echo -e "${YELLOW}📌 [Step 1] Updating and upgrading Ubuntu ${UBUNTU_CODENAME} instance...${RESET}\n"
# sudo apt update && sudo apt upgrade -y
# echo -e "${GREEN}✅ System updated and upgraded.${RESET}\n"

# Step 1: Install required packages
echo -e "${YELLOW}📌 [Step 1] Installing required packages...${RESET}\n"
sudo apt install -y apt-transport-https wget gnupg lsb-release
echo -e "${GREEN}✅ Required packages installed.${RESET}\n"

# Step 2: Add Icinga2 GPG key
echo -e "${YELLOW}📌 [Step 2] Adding Icinga2 GPG key...${RESET}\n"
wget -O - https://packages.icinga.com/icinga.key | gpg --dearmor | sudo tee /usr/share/keyrings/icinga-archive-keyring.gpg > /dev/null
echo -e "${GREEN}✅ Icinga2 GPG key added.${RESET}\n"

# Step 3: Add Icinga2 repository dynamically based on Ubuntu release
echo -e "${YELLOW}📌 [Step 3] Adding Icinga2 repository for Ubuntu ${UBUNTU_CODENAME}...${RESET}\n"
echo "deb [signed-by=/usr/share/keyrings/icinga-archive-keyring.gpg] https://packages.icinga.com/ubuntu icinga-${UBUNTU_CODENAME} main" | sudo tee /etc/apt/sources.list.d/icinga-${UBUNTU_CODENAME}.list
echo "deb-src [signed-by=/usr/share/keyrings/icinga-archive-keyring.gpg] https://packages.icinga.com/ubuntu icinga-${UBUNTU_CODENAME} main" | sudo tee -a /etc/apt/sources.list.d/icinga-${UBUNTU_CODENAME}.list
echo -e "${GREEN}✅ Icinga2 repository added.${RESET}\n"

# Step 4: Update package lists
echo -e "${YELLOW}📌 [Step 4] Updating package lists...${RESET}\n"
sudo apt update
echo -e "${GREEN}✅ Package lists updated.${RESET}\n"

# Step 5: List available Icinga2 versions
echo -e "${YELLOW}📌 [Step 5] Fetching available Icinga2 versions...${RESET}\n"
AVAILABLE_VERSIONS=$(apt-cache madison icinga2 | awk '{print $3}')
echo -e "Available versions:\n${AVAILABLE_VERSIONS}\n"

# Step 6: Prompt user to select a version
echo -ne "${YELLOW}📌 [Step 6] Enter the Icinga2 version to install (or press Enter for latest): ${RESET}"
read SELECTED_VERSION

# If no version is provided, install the latest one
if [[ -z "$SELECTED_VERSION" ]]; then
    SELECTED_VERSION="icinga2"
    echo -e "${GREEN}✅ Installing latest version of Icinga2.${RESET}\n"
else
    SELECTED_VERSION=${SELECTED_VERSION}
    echo -e "${GREEN}✅ Installing Icinga2 version ${SELECTED_VERSION}.${RESET}\n"
fi

# Step 7: Install the chosen Icinga2 version
echo -e "${YELLOW}📌 [Step 7] Installing ${SELECTED_VERSION} and required packages...${RESET}\n"
sudo apt install -y icinga2=$SELECTED_VERSION icinga2-bin=$SELECTED_VERSION icinga2-common=$SELECTED_VERSION monitoring-plugins nagios-nrpe-plugin
echo -e "${GREEN}✅ Icinga2 installed successfully.${RESET}\n"

# Step 8: Check if Icinga2 service is running
echo -e "${YELLOW}📌 [Step 8] Checking Icinga2 service status...${RESET}\n"
if systemctl is-active --quiet icinga2; then
    echo -e "${GREEN}✅ Icinga2 service is running.${RESET}\n"
else
    echo -e "${RED}❌ Icinga2 service is NOT running. Please check logs.${RESET}\n"
fi

# Step 9: Ensure /var/lib/icinga2/certs directory exists and has the correct permissions
echo -e "${YELLOW}📌 [Step 9] Ensuring /var/lib/icinga2/certs directory exists and has correct permissions...${RESET}\n"
sudo mkdir -p /var/lib/icinga2/certs
sudo chown -R nagios:nagios /var/lib/icinga2/certs
echo -e "${GREEN}✅ Directory ensured and permissions set.${RESET}\n"

# Step 10: Generate a new local self-signed certificate (for the agent node)
echo -e "${YELLOW}📌 [Step 10] Generating a new local self-signed certificate...${RESET}\n"
HOSTNAME="$LOCAL_ZONE_NAME"
icinga2 pki new-cert --cn $HOSTNAME \
  --key /var/lib/icinga2/certs/$HOSTNAME.key \
  --cert /var/lib/icinga2/certs/$HOSTNAME.crt
echo -e "${GREEN}✅ Certificate generated.${RESET}\n"

# Step 11: Verify Parent Connection by fetching the parent instance’s certificate
echo -e "${YELLOW}📌 [Step 11] Verifying parent connection by fetching the master certificate...${RESET}\n"
MASTER_HOST="$MASTER_IP_FQDN" 
icinga2 pki save-cert --trustedcert /var/lib/icinga2/certs/trusted-parent.crt \
  --host $MASTER_HOST
echo -e "${GREEN}✅ Parent certificate saved.${RESET}\n"

# Step 12: Enable Icinga2 API
echo -e "${YELLOW}📌 [Step 12] Enabling Icinga2 API...${RESET}\n"
sudo icinga2 api setup
echo -e "${GREEN}✅ Icinga2 API enabled.${RESET}\n"

# Step 13: Configure Icinga2 Node using CLI parameters
echo -e "${YELLOW}📌 [Step 13] Configuring Icinga2 Node...${RESET}\n"
sudo icinga2 node setup \
  --endpoint "$MASTER_HOSTNAME,$MASTER_IP_FQDN,5665" \
  --cn "$LOCAL_ZONE_NAME" \
  --zone "$LOCAL_ZONE_NAME" \
  --parent_zone master \
  --parent_host "$MASTER_IP_FQDN" \
  --trustedcert /var/lib/icinga2/certs/trusted-parent.crt \
  --ticket "$TICKET" \
  --accept-commands \
  --accept-config \
  --disable-confd
echo -e "${GREEN}✅ Icinga2 Node configured.${RESET}\n"

# Step 14: Clear existing content in api-users.conf and add API user
echo -e "${YELLOW}📌 [Step 14] Clearing and adding API user to /etc/icinga2/conf.d/api-users.conf...${RESET}\n"

# Clear the file first
sudo truncate -s 0 /etc/icinga2/conf.d/api-users.conf

# Create or add the ApiUser object to the file
echo -e "\n/**
 * The ApiUser objects are used for authentication against the API.
 */
object ApiUser \"$API_USERNAME\" {
  password = \"$API_PASSWORD\"
  permissions = [ \"*\" ]
}" | sudo tee -a /etc/icinga2/conf.d/api-users.conf > /dev/null

echo -e "${GREEN}✅ API user added to /etc/icinga2/conf.d/api-users.conf.${RESET}\n"

# Step 15: Rename hosts.conf file if it exists
echo -e "${YELLOW}📌 [Step 15] Checking if hosts.conf exists before renaming...${RESET}"
if [ -f /etc/icinga2/conf.d/hosts.conf ]; then
    sudo mv /etc/icinga2/conf.d/hosts.conf /etc/icinga2/conf.d/hosts.conf.bak
    echo -e "${GREEN}✅ hosts.conf file renamed to hosts.conf.bak.${RESET}\n"
else
    echo -e "${BLUE}🛠️  hosts.conf file not found. Skipping this step.${RESET}\n"
fi

# Step 16: Restart Icinga2
echo -e "${YELLOW}📌 [Step 15] Restarting Icinga2 service...${RESET}\n"
sudo systemctl restart icinga2
echo -e "${GREEN}✅ Icinga2 service restarted.${RESET}\n"

# Step 17: Add check_mem.pl command
echo -e "${YELLOW}📌 [Step 17] Adding check_mem.pl nagios command...${RESET}\n"
sudo cp check_mem.pl /usr/lib/nagios/plugins/
echo -e "${GREEN}✅ Added check_mem.pl nagios command.${RESET}\n"

# Step 18: Final status check
echo -e "${YELLOW}📌 [Step 18] Final Icinga2 service status check...${RESET}\n"
if systemctl is-active --quiet icinga2; then
    echo -e "${GREEN}✅ Icinga2 service is running.${RESET}\n"
else
    echo -e "${RED}❌ Icinga2 service is NOT running. Please check logs.${RESET}\n"
fi

echo -e "${GREEN}✅ Icinga2 setup completed successfully! 🎉${RESET}\n"
