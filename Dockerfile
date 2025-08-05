#-----------------------------------------------------------------------------
# BASE IMAGE
#-----------------------------------------------------------------------------
# Use Alpine Linux as base image for minimal size and security
FROM alpine:3

#-----------------------------------------------------------------------------
# METADATA
#-----------------------------------------------------------------------------
# Define maintainer information for the container image
LABEL maintainer="Focela Engineering <opensource@focela.com> https://www.focela.com"

#-----------------------------------------------------------------------------
# BUILD ARGUMENTS
#-----------------------------------------------------------------------------
# Define target architecture for multi-platform builds
ARG TARGETARCH

#-----------------------------------------------------------------------------
# DEPENDENCIES INSTALLATION
#-----------------------------------------------------------------------------
# Copy and execute installation script to set up required packages
COPY ./src/install.sh install.sh
RUN sh install.sh && rm install.sh

#-----------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
#-----------------------------------------------------------------------------
# Define default environment variables for backup configuration
ENV HOST_BACKUP_PATH ''
ENV CONTAINER_BACKUP_PATH ''
ENV BACKUP_FILE_NAME ''
ENV S3_ACCESS_KEY_ID ''
ENV S3_SECRET_ACCESS_KEY ''
ENV S3_BUCKET ''
ENV S3_REGION ''
ENV S3_PREFIX ''
ENV S3_ENDPOINT ''
ENV S3_S3V4 ''
ENV CRON_SCHEDULE ''
ENV GPG_PASSPHRASE ''
ENV BACKUP_KEEP_DAYS ''

#-----------------------------------------------------------------------------
# APPLICATION FILES
#-----------------------------------------------------------------------------
# Copy application scripts into the container
COPY ./src/run.sh run.sh
COPY ./src/env.sh env.sh
COPY ./src/backup.sh backup.sh
COPY ./src/restore.sh restore.sh

#-----------------------------------------------------------------------------
# CONTAINER ENTRYPOINT
#-----------------------------------------------------------------------------
# Set default command to run the main entry point script
CMD ["sh", "run.sh"]
