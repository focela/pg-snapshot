#! /bin/sh
#-----------------------------------------------------------------------------
# Container Dependencies Installation Script
#
# Purpose: Installs required packages and tools for the storage-snapshot service
# Context: Runs during container build process to set up runtime dependencies
# Note: Uses Alpine Linux package manager (apk) and targets specific architecture
#-----------------------------------------------------------------------------



#-----------------------------------------------------------------------------
# SCRIPT CONFIGURATION
#-----------------------------------------------------------------------------
# Enable strict error handling and debugging
set -eux
set -o pipefail

#-----------------------------------------------------------------------------
# PACKAGE MANAGER UPDATE
#-----------------------------------------------------------------------------
# Refresh package index to ensure latest package information
apk update

#-----------------------------------------------------------------------------
# CORE DEPENDENCIES INSTALLATION
#-----------------------------------------------------------------------------
# Install GPG for cryptographic operations
apk add gnupg

# Install Python runtime and package manager
apk add python3
apk add py3-pip

# Install AWS CLI for cloud service interactions
pip3 install awscli --break-system-packages

#-----------------------------------------------------------------------------
# GO-CRON INSTALLATION
#-----------------------------------------------------------------------------
# Install curl for downloading go-cron binary
apk add curl

# Download go-cron scheduler binary for target architecture
go_cron_version="0.0.5"
go_cron_archive="go-cron_${go_cron_version}_linux_${TARGETARCH}.tar.gz"
curl -L "https://github.com/ivoronin/go-cron/releases/download/v${go_cron_version}/${go_cron_archive}" -O

# Extract and install go-cron binary
tar xvf "$go_cron_archive"
rm "$go_cron_archive"
mv go-cron /usr/local/bin/go-cron
chmod u+x /usr/local/bin/go-cron

# Remove curl after download
apk del curl

#-----------------------------------------------------------------------------
# CLEANUP
#-----------------------------------------------------------------------------
# Remove package cache
rm -rf /var/cache/apk/*
