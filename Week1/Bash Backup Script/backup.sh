!#/bin/bash
set -euo pipefail
IFS=$'\n\t'


###################################################################################

# Program:          backup.sh
# Author:           Valentyn Volodchenko
# Date:             May 10, 2026
# Description:      This script creates a backup of a specified file or directory,
#                   with options for encryption and AWS S3 upload. 
#                   It also schedules deletion of old backups based on retention days.
# Usage:            ./backup.sh -s <source_dir_file> -d <destination_dir> -r <retention_days> [-e] [-u <aws_s3_bucket_name>]

###################################################################################


# DECLARARIONS:
LOG_FILE="./backup.log"
source_dir_file=""
destination_dir=""
retention_days=""
encryption_key="false" 
aws_s3_bucket_name=""


# FUNCTIONS:
# Function which handles signals (EXIT, INT, TERM) and logs the signal before exiting the script.
signal_handler() {
    log INFO "Signal received, exiting..."}
    echo "Signal received, exiting..."
    exit 1
}
trap signal_handler INT TERM

# Function which logs messages with timestamps and log levels to a log file.
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] ${@:2}" | tee -a "$LOG_FILE"
}


# Function which validates if inputs for the required parameters 
# (-s source_dir_file, -d destination_dir, -r retention_days) are provided, and if they are valid.
req_input_validation() {
    if [[ -z "$source_dir_file" || -z "$destination_dir" || -z "$retention_days" ]]; then
    log ERROR "Source directory, destination directory, and retention days are required" >&2
    exit 1
    fi

    # Validates if the source if a file or a directory, 
    # and checks if it has the necessary permissions to be backed up. 
    # Directories need to be readable and executable.
    # Files need to be readable.
    if [[ -d "$source_dir_file" ]]; then
        if [[ ! -r "$source_dir_file" ]]; then
            log ERROR "$source_dir_file exists, but is not readable" >&2
            exit 1
        elif [[ ! -x "$source_dir_file" ]]; then
            log ERROR "$source_dir_file exists and is not executable" >&2   
            exit 1
        else
            log INFO "Source directory is readable and executable: $source_dir_file"
        fi
    elif [[ -f "$source_dir_file" ]]; then
        if [[ ! -r "$source_dir_file" ]]; then
            log ERROR "$source_dir_file exists, but is not readable" >&2
            exit 1
        else
            log INFO "Source file exists and is readable: $source_dir_file"
        fi
    elif [[ ! -d $source_dir_file || ! -f "$source_dir_file" ]]; then
        log ERROR "Source should be file or directory, check your input: $source_dir_file" >&2
        exit 1
    fi


    if [[ -d "$destination_dir" ]]; then
        if [[ -w "$destination_dir" ]]; then
            log INFO "Destination directory exists and is writable: $destination_dir"
        else
            log ERROR "Destination directory exists but is not writable: $destination_dir" >&2
            exit 1
        fi
    else
        log ERROR "Destination directory does not exist: $destination_dir" >&2
        exit 1
    fi

    # Validates if retention days is a positive integer, hihger than 0
    if [[ ! "$retention_days" =~ ^[1-9][0-9]*$ ]]; then
        log ERROR "Retention days must be a positive integer: $retention_days" >&2
        exit 1
    fi
}


# Function which creates a backup of the specified file or directory,
# and saves it in the specified destination directory with a timestamped + original file/directory name.
backup_basic () {
    backup_file="$destination_dir/backup_$(basename "$source_dir_file")_$(date +%Y%m%d%H%M%S).tar.gz"
    tar -czvf "$backup_file" -C "$(dirname "$source_dir_file")" "$(basename "$source_dir_file")"
    log INFO "Backup created: $backup_file"
}

# Function which encrypts the backup file using gpg symmetric encryption,
# and user provided password. 
# The original unencrypted backup file is deleted after encryption.
# Instructions for decryption are provided to the user after encryption is complete.
# Checks if the 'gpg' command is installed, and provides instructions for installation if not.
backup_encryption() {
    if [[ "$encryption_key" == "True" ]]; then
        if ! command -v gpg > /dev/null 2>&1; then
            log ERROR "The 'gpg' command is required for encryption" >&2
            log WARN "Install 'gpg' using: sudo apt-get install gnupg"
            exit 1
        fi
        read -rsp "Enter encryption password: " encryption_password
        printf '%s' "$encryption_password" | gpg --batch --yes --passphrase-fd 0 -c "$backup_file"
        rm -f "$backup_file"
        backup_file="$backup_file.gpg"
        log INFO "Backup encrypted: $backup_file"
        log INFO "You can decrypt the backup using:"
        log INFO "gpg -d $backup_file > decrypted_backup.tar.gz"
        echo "Backup encrypted: $backup_file"
        echo "You can decrypt the backup using:"
        echo "gpg -d $backup_file > decrypted_backup.tar.gz"
    fi
}


# Function which schedules the deletion of the backup file 
# using the 'at' command and user specified retention days (period).
# Checks if the 'at' command is installed, and if not, provides instructions for installation.
delete_expired_backups() {
    if ! command -v at > /dev/null 2>&1; then
        log ERROR "The 'at' command is required to schedule backup deletion" >&2
        log WARN "install 'at' using: sudo apt-get install at"
        exit 1
    fi
    echo "rm -f '$backup_file'" | at now + "$retention_days" days
    log INFO "Deletion of $backup_file scheduled on $(date -d "+$retention_days days" +"%Y-%m-%d")"
    echo "Deletion of $backup_file scheduled on $(date -d "+$retention_days days" +"%Y-%m-%d")"
}


# Function which uploads the backup file to AWS S3 bucket using the 'aws' CLI.
# Additionaly checks if the 'aws' CLI is installed and configured properly, and if the S3 bucket name is provided.
# Provides instructions, if not installed or configured.
aws_s3_upload() {
    if ! command -v aws > /dev/null 2>&1; then
        log ERROR "The 'aws' CLI is required to upload to S3, install and configure it using:" >&2
        log WARN "Install and configure AWS CLI using: sudo apt-get install awscli"
        exit 1
    fi
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        log ERROR "AWS CLI is not configured properly. Please configure it using:" >&2
        log WARN "Please configure AWS CLI using: aws configure"
        exit 1
    fi

    if [[ -z "$aws_s3_bucket_name" ]]; then
        log ERROR "AWS S3 bucket name is required for upload." >&2
        exit 1
    fi
    aws s3 cp "$backup_file" "s3://$aws_s3_bucket_name/$(basename "$backup_file")"
    log INFO "Backup uploaded to S3 bucket: $aws_s3_bucket_name"
    echo "Backup uploaded to S3 bucket: $aws_s3_bucket_name"
}

# PROCESS:
# Parsing command line options using getopts, and assigning provided values by user to variables.
# Displaying usage message if required parameters are not provided, or if invalid options are provided.
while getopts "s:d:r:eu:" opt; do
    case $opt in
        s) source_dir_file="$OPTARG" ;;
        d) destination_dir="$OPTARG" ;;
        r) retention_days="$OPTARG" ;;
        e) encryption_key="True" ;;
        u) aws_s3_bucket_name="$OPTARG" ;;
        *) echo "Usage: $0 -s <source_dir_file> -d <destination_dir> \
        -r <retention_days> -e Enable encryption -u <aws_s3_bucket_name>" >&2
        exit 1 ;;
    esac
done

# Calling the function which validates the required inputs, and checks if they are valid.
req_input_validation

# Calling the functions in the correct order, based on the provided options for encryption and AWS S3 upload.
if [[ -n "$aws_s3_bucket_name" && "$encryption_key" == "True" ]]; then
    backup_basic
    backup_encryption
    aws_s3_upload
    delete_expired_backups
elif [[ -n "$aws_s3_bucket_name" ]]; then
    backup_basic
    aws_s3_upload
    delete_expired_backups
elif [[ "$encryption_key" == "True" ]]; then
    backup_basic
    backup_encryption
    delete_expired_backups
else
    backup_basic
    delete_expired_backups
fi



