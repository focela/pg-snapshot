#! /bin/sh
#-----------------------------------------------------------------------------
# Container Entry Point Script
#
# Purpose: Configures AWS S3 settings and executes backup operations with optional scheduling
# Context: Runs as the main entry point for the storage-snapshot container
# Note: Supports both immediate backup execution and scheduled backup operations
#-----------------------------------------------------------------------------



#-----------------------------------------------------------------------------
# SCRIPT CONFIGURATION
#-----------------------------------------------------------------------------
# Enable strict error handling
set -eu

#-----------------------------------------------------------------------------
# AWS S3 CONFIGURATION
#-----------------------------------------------------------------------------
# Configure S3 signature version if specified
if [ "$S3_S3V4" = "yes" ]; then
  aws configure set default.s3.signature_version s3v4
fi

#-----------------------------------------------------------------------------
# BACKUP EXECUTION
#-----------------------------------------------------------------------------
# Execute backup immediately or with scheduling
if [ -z "$CRON_SCHEDULE" ]; then
  # Run backup once immediately
  sh backup.sh
else
  # Run backup on schedule using go-cron
  exec go-cron "$CRON_SCHEDULE" /bin/sh backup.sh
fi
