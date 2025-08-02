#! /bin/sh
#-----------------------------------------------------------------------------
# S3 Backup Restore Script
#
# Purpose: Downloads and restores backup files from S3 storage with optional GPG decryption
# Context: Runs during container startup or manual restore operations to recover data
# Note: Supports both encrypted (.gpg) and plain (.tar.gz) backup files
#-----------------------------------------------------------------------------



#-----------------------------------------------------------------------------
# SCRIPT CONFIGURATION
#-----------------------------------------------------------------------------
# Enable strict error handling and pipe failure detection
set -eu
set -o pipefail

# Load environment configuration
source ./env.sh

#-----------------------------------------------------------------------------
# BACKUP FILE CONFIGURATION
#-----------------------------------------------------------------------------
# Construct S3 URI base path
s3_uri_base="s3://${S3_BUCKET}/${S3_PREFIX}"

# Determine file type based on encryption
if [ -z "$GPG_PASSPHRASE" ]; then
  backup_file_extension=".tar.gz"
else
  backup_file_extension=".tar.gz.gpg"
fi

#-----------------------------------------------------------------------------
# BACKUP SELECTION LOGIC
#-----------------------------------------------------------------------------
# Use provided timestamp or find latest backup
if [ $# -eq 1 ]; then
  restore_timestamp="$1"
  backup_key_suffix="${BACKUP_FILE_NAME}_${restore_timestamp}${backup_file_extension}"
else
  echo "Finding latest backup..."
  backup_key_suffix=$(
    aws $aws_cli_args s3 ls "${s3_uri_base}/${BACKUP_FILE_NAME}" \
      | sort \
      | tail -n 1 \
      | awk '{ print $4 }'
  )
fi

#-----------------------------------------------------------------------------
# BACKUP DOWNLOAD AND RESTORE
#-----------------------------------------------------------------------------
# Download backup file from S3
echo "Fetching backup from S3..."
aws $aws_cli_args s3 cp "${s3_uri_base}/${backup_key_suffix}" "${BACKUP_FILE_NAME}${backup_file_extension}"

# Decrypt backup if GPG passphrase is provided
if [ -n "$GPG_PASSPHRASE" ]; then
  echo "Decrypting backup..."
  gpg --decrypt --batch --passphrase "$GPG_PASSPHRASE" "${BACKUP_FILE_NAME}.tar.gz.gpg" > "${BACKUP_FILE_NAME}.tar.gz"
  rm "${BACKUP_FILE_NAME}.tar.gz.gpg"
fi

# Extract backup archive to target directory
echo "Restoring from backup..."
tar -xf "${BACKUP_FILE_NAME}.tar.gz" --directory "$CONTAINER_BACKUP_PATH"
rm "${BACKUP_FILE_NAME}.tar.gz"

echo "Restore complete."
