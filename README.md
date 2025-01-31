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
   cd icinga2-satellite-setup```
