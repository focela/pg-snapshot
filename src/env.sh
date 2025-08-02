#! /bin/sh
#-----------------------------------------------------------------------------
# Environment Configuration Script
#
# Purpose: Validates and configures AWS S3 environment variables for storage operations
# Context: Runs during container startup to ensure required environment variables are set
# Note: Exits with error code 1 if required variables are missing
#-----------------------------------------------------------------------------



#-----------------------------------------------------------------------------
# REQUIRED ENVIRONMENT VARIABLES VALIDATION
#-----------------------------------------------------------------------------
# Check if S3_BUCKET environment variable is set
if [ -z "$S3_BUCKET" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

# Check if HOST_BACKUP_PATH environment variable is set (for volume mount)
if [ -z "$HOST_BACKUP_PATH" ]; then
  echo "You need to set the HOST_BACKUP_PATH environment variable."
  exit 1
fi

# Set default container backup directory if not specified
if [ -z "$CONTAINER_BACKUP_PATH" ]; then
  CONTAINER_BACKUP_PATH="/home/backups"
fi

# Check if BACKUP_FILE_NAME environment variable is set
if [ -z "$BACKUP_FILE_NAME" ]; then
  echo "You need to set the BACKUP_FILE_NAME environment variable."
  exit 1
fi

#-----------------------------------------------------------------------------
# AWS CLI CONFIGURATION
#-----------------------------------------------------------------------------
# Configure AWS CLI endpoint if S3_ENDPOINT is provided
if [ -z "$S3_ENDPOINT" ]; then
  aws_cli_args=""
else
  aws_cli_args="--endpoint-url $S3_ENDPOINT"
fi

# Set AWS access key ID if provided (for authentication)
if [ -n "$S3_ACCESS_KEY_ID" ]; then
  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
fi

# Set AWS secret access key if provided (for authentication)
if [ -n "$S3_SECRET_ACCESS_KEY" ]; then
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
fi

# Set AWS default region
export AWS_DEFAULT_REGION=$S3_REGION
