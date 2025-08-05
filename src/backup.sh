#! /bin/sh
#-----------------------------------------------------------------------------
# S3 Backup Creation Script
#
# Purpose: Creates and uploads backup archives to S3 storage with optional GPG encryption
# Context: Runs during scheduled backup operations or manual backup requests
# Note: Supports automatic cleanup of old backups based on retention policy
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
# BACKUP CREATION
#-----------------------------------------------------------------------------
# Create compressed archive of backup directory
echo "Creating backup of $BACKUP_FILE_NAME..."
tar -czvf "${BACKUP_FILE_NAME}.tar.gz" -C "$CONTAINER_BACKUP_PATH" .

# Generate timestamp for backup file naming
backup_timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
s3_uri_base="s3://${S3_BUCKET}/${S3_PREFIX}/${BACKUP_FILE_NAME}_${backup_timestamp}.tar.gz"

#-----------------------------------------------------------------------------
# ENCRYPTION AND UPLOAD
#-----------------------------------------------------------------------------
# Encrypt backup if GPG passphrase is provided
if [ -n "$GPG_PASSPHRASE" ]; then
  echo "Encrypting backup..."
  rm -f "${BACKUP_FILE_NAME}.tar.gz.gpg"
  gpg --symmetric --batch --passphrase "$GPG_PASSPHRASE" "${BACKUP_FILE_NAME}.tar.gz"
  rm "${BACKUP_FILE_NAME}.tar.gz"
  local_backup_file="${BACKUP_FILE_NAME}.tar.gz.gpg"
  s3_backup_uri="${s3_uri_base}.gpg"
else
  local_backup_file="${BACKUP_FILE_NAME}.tar.gz"
  s3_backup_uri="$s3_uri_base"
fi

# Upload backup file to S3 storage
echo "Uploading backup to $S3_BUCKET..."
aws $aws_cli_args s3 cp "$local_backup_file" "$s3_backup_uri"
rm "$local_backup_file"

echo "Backup complete."

#-----------------------------------------------------------------------------
# OLD BACKUP CLEANUP
#-----------------------------------------------------------------------------
# Remove old backups if retention policy is configured
if [ -n "$BACKUP_KEEP_DAYS" ]; then
  # Validate BACKUP_KEEP_DAYS is a positive number
  if ! [ "$BACKUP_KEEP_DAYS" -gt 0 ] 2>/dev/null; then
    echo "Warning: BACKUP_KEEP_DAYS must be a positive number, skipping cleanup."
  else
    # Calculate cutoff date for backup removal (Alpine Linux compatible)
    # Use awk for reliable date arithmetic with proper month handling
    cutoff_date=$(awk -v days="$BACKUP_KEEP_DAYS" 'BEGIN {
      # Get current date
      cmd = "date +%Y-%m-%d"
      cmd | getline today
      close(cmd)
      split(today, date_parts, "-")
      year = date_parts[1] + 0
      month = date_parts[2] + 0
      day = date_parts[3] + 0
      
      # Days in each month (non-leap year)
      month_days[1] = 31; month_days[2] = 28; month_days[3] = 31
      month_days[4] = 30; month_days[5] = 31; month_days[6] = 30
      month_days[7] = 31; month_days[8] = 31; month_days[9] = 30
      month_days[10] = 31; month_days[11] = 30; month_days[12] = 31
      
      # Subtract days
      day = day - days
      
      # Adjust for negative days
      while (day <= 0) {
        month = month - 1
        if (month <= 0) {
          month = 12
          year = year - 1
        }
        # Handle leap year for February
        if (month == 2 && year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
          day = day + 29
        } else {
          day = day + month_days[month]
        }
      }
      
      printf "%04d-%02d-%02dT00:00:00.000Z", year, month, day
    }')
    
    # Verify awk calculation succeeded
    if [ -z "$cutoff_date" ] || [ "$cutoff_date" = "0000-00-00T00:00:00.000Z" ]; then
      echo "Warning: Failed to calculate cutoff date, skipping cleanup."
    else
      old_backups_query="Contents[?LastModified<='${cutoff_date}'].{Key: Key}"

      echo "Removing old backups from $S3_BUCKET..."
      # List and remove old backup objects from S3
      aws $aws_cli_args s3api list-objects \
        --bucket "${S3_BUCKET}" \
        --prefix "${S3_PREFIX}/${BACKUP_FILE_NAME}_" \
        --query "${old_backups_query}" \
        --output text \
        | xargs -n1 -t -I KEY aws $aws_cli_args s3 rm s3://"${S3_BUCKET}"/KEY
      echo "Removal complete."
    fi
  fi
fi
