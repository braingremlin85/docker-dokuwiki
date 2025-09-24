#!/bin/bash

# https://github.com/edyatl/dokuwiki-update-helper/tree/master

# Exit immediately if a command exits with a non-zero status
set -e

# Constants
#DOKUWIKI_PATH="/var/www/html" # debian
DOKUWIKI_DIR="/var/www/localhost/htdocs" # alpine
BACKUP_DIR="/home/dokuwiki-backup"
PUID=${PUID:-100} # apache user
PGID=${PGID:-101} # apache group

DOKUWIKI_DIR="$HOME/tmp" # alpine

DOWNLOAD_URL="https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz"

# Define color codes
BOLD="\033[1m"
RED="\033[0;31m"
GREEN="\033[0;32m"
RESET="\033[0m"

# script start

show_help() {
    echo -e "${BOLD}Usage:${RESET} $0 [OPTIONS]"
    echo -e "${BOLD}Options:${RESET}"
    echo -e "  --no-backup    Do not create a backup before updating."
    echo -e "  --silent, -s   Install without asking for confirmation"
    echo -e "  --help         Display this help message."
    echo -e "${BOLD}Description:${RESET}"
    echo -e "  This script updates/install DokuWiki to the latest stable version."
    echo -e "  Use -s for automated silent install"
    exit 0
}

cd $HOME

nobackup=false
silent=false
for arg in "$@"; do
    case "$arg" in
        --no-backup)
            nobackup=true
            ;;
        --silent | -s)
            silent=true
            ;;
        --help)
            show_help
            ;;
    esac
done

# Show current DokuWiki version
if [ -f "$DOKUWIKI_DIR/VERSION" ]; then
    echo "Current DokuWiki version:"
    version=$(cat "$DOKUWIKI_DIR/VERSION")
    echo -e ${GREEN}${version}${RESET}
else
    nobackup=true
    if [ "$silent" = false ]; then
        echo "VERSION file not found! Do you want to install DokuWiki? (Y/n)"
        read -r response
        response=${response:-y}  # Set default to 'y' if no input is given
        if [[ "$response" == "y" || "$response" == "Y" ]]; then
            echo "Proceeding with installation..."
        else
            echo "Exiting..."
            exit 1
        fi
    fi
fi


# Backup existing version
if [ "$nobackup" = false ]; then
    # Check and create backup directory if not exists
    echo "Checking if backup directory exist..."
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "...it doesn't exist, let's create it"
        mkdir -p "$BACKUP_DIR"
    else
        echo "...yes!"
    fi

    # 3. Make a backup file
    backup_file="$BACKUP_DIR/dokuwiki-backup-$(date +%Y-%m-%d).tar.gz"
    echo "Let's backup!"
    tar -czvf "$backup_file" "$DOKUWIKI_DIR"
    echo "Backup successful: '$backup_file' created"
fi

# Download current stable release
wget "$DOWNLOAD_URL" || exit 1
echo "Download successful :)"


# Unpack tarball
tar zxvf dokuwiki-stable.tgz
echo "Extraction complete!"

# Identify the correct unpacked directory
unpacked_dir=$(ls -d dokuwiki-[0-9]*)

# Verify unpacked directory exists
if [ -d "$unpacked_dir" ]; then
    new_version=$(cat "$unpacked_dir/VERSION")
    echo -e "Installed: ${BOLD}${version}${RESET}"
    echo -e "Latest:    ${BOLD}${GREEN}${version}${RESET}"
    if [ "$version" = "$new_version" ]; then
        echo "Latest version already installed!"
        # TODO reinstall
        exit 1
    else
        # Copy files to /var/www/dokuwiki/
        cp -af "$unpacked_dir"/* "$DOKUWIKI_DIR/"
        echo "Files successfully copied to '$DOKUWIKI_DIR'"
    fi

else
    echo "Unpacked directory not found! Exiting..."

fi

# Change ownership of $DOKUWIKI_DIR
#chown -R $PUID:$PGID "$DOKUWIKI_DIR" || echo "Error: can't set ownership of \"$DOKUWIKI_DIR\" for PUID=$PUID GUID=$PGID"; exit 1

#% Remove tarball and unpacked directory
rm dokuwiki-stable.tgz || exit 1
rm -rf "$unpacked_dir" || exit 1

# 11. Show updated DokuWiki version
if [ -f "$DOKUWIKI_DIR/VERSION" ]; then
# Define color codes

# Print the updated DokuWiki version
echo -e "${BOLD}Updated DokuWiki version:${RESET}"
version=$(cat "$DOKUWIKI_DIR/VERSION")
echo -e ${GREEN}${version}${RESET}

else
    echo "VERSION file not found after update! Something might have gone wrong."
    exit 1
fi
