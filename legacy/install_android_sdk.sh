#!/bin/bash

# Author:       chris
# Reason:       Set up a basic environment for workshop
# Usage:        chmod u+x install_android_sdk.sh && ./install_android_sdk.sh
# Description:  This script downloads the Android SDK command line tools and sets up the necessary environment variables.
# IMPORTANT:    commandlinetools version is tied to the URL, please update the URL if the version changes.

# Exit on error
set -e

# Helper functions
print_msg() {
    printf "$(tput bold)::: %s :::\n$(tput sgr0)" "$1"
}

print_msg_multiline() {
    printf "$(tput bold)::: $(tput sgr0)\n"
    while IFS= read -r line; do
        printf "%s\n" "$line"
    done
    printf "$(tput bold)::: $(tput sgr0)\n"
}

print_err_msg() {
    printf "$(tput setaf 1)-> %s <-\n$(tput sgr0)" "$1"
}

# Install prerequisites
install_prerequisites() {
    print_msg "Checking prerequisites..."

    # Check if wget is installed
    if ! command -v wget &> /dev/null; then
        print_err_msg "wget is not installed. Please install wget manually and rerun the script."
        exit 1
    fi

    # Check if unzip is installed
    if ! command -v unzip &> /dev/null; then
        print_msg "unzip could not be found, installing..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update
            sudo apt-get install -y unzip
        else
            print_err_msg "Unable to install unzip. Please install it manually."
            exit 1
        fi
    fi

    print_msg "Prerequisites confirmed."
}

# Download and extract Android SDK
download_and_extract_sdk() {
    print_msg "Downloading Android SDK..."

    # Fetch the latest version from Android's repository XML
    print_msg "Fetching latest commandlinetools version..."
    REPO_XML=$(wget -qO- https://dl.google.com/android/repository/repository2-3.xml)
    LATEST_VERSION=$(echo "$REPO_XML" | grep -oP 'commandlinetools-linux-[0-9]+_latest\.zip' | head -1)

    if [[ -z "$LATEST_VERSION" ]]; then
        print_err_msg "Failed to fetch latest version. Falling back to known version."
        LATEST_VERSION="commandlinetools-linux-11076708_latest.zip"
    fi

    print_msg "Using version: $LATEST_VERSION"
    URL="https://dl.google.com/android/repository/$LATEST_VERSION"
    OUTPUT="$LATEST_VERSION"

    ANDROID_SDK_ROOT_DIR="$(pwd)/android_sdk"

    if [[ -d "$ANDROID_SDK_ROOT_DIR" ]]; then
        print_err_msg "Directory $ANDROID_SDK_ROOT_DIR already exists. Please delete and run script again."
        exit 1
    else
        wget -O "$OUTPUT" "$URL"
        print_msg "Unzipping downloaded package..."
        mkdir -p "$ANDROID_SDK_ROOT_DIR/cmdline-tools"
        unzip -q "$OUTPUT" -d "$ANDROID_SDK_ROOT_DIR/cmdline-tools"
        # Restructure to proper SDK layout: cmdline-tools/latest/
        mv "$ANDROID_SDK_ROOT_DIR/cmdline-tools/cmdline-tools" "$ANDROID_SDK_ROOT_DIR/cmdline-tools/latest"
        rm "$OUTPUT" # Clean up the downloaded ZIP file after unzipping
    fi
}

# Configure environment variables
configure_environment() {
    print_msg "Configuring environment variables..."

    # Detect the current shell
    CURRENT_SHELL=$(ps -p $(ps -o ppid= -p $$) -o comm=)

    # Determine the shell configuration file dynamically
     case "$CURRENT_SHELL" in
        zsh)
            SHELL_CONFIG_FILE="$HOME/.zshrc"
            ;;
        bash)
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                # Linux: Prefer ~/.bashrc, fallback to ~/.profile
                if [[ -f "$HOME/.bashrc" ]]; then
                    SHELL_CONFIG_FILE="$HOME/.bashrc"
                else
                    SHELL_CONFIG_FILE="$HOME/.profile"
                fi
            else
                print_msg "Unsupported OS: $OSTYPE. Defaulting to ~/.bashrc."
                SHELL_CONFIG_FILE="$HOME/.bashrc"
            fi
            ;;
        *)
            print_msg "Unknown or unsupported shell ($CURRENT_SHELL). Defaulting to ~/.bashrc."
            SHELL_CONFIG_FILE="$HOME/.bashrc"
            ;;
    esac

    print_msg "Using shell configuration file: $SHELL_CONFIG_FILE"

    if grep -q "ANDROID_SDK_ROOT=" "$SHELL_CONFIG_FILE"; then
        print_msg "ANDROID_SDK_ROOT is already configured in $SHELL_CONFIG_FILE. Skipping addition."
    else
        print_msg "Adding ANDROID_SDK_ROOT and PATH modifications to $SHELL_CONFIG_FILE"

        # Find the line number of the last occurrence of 'export PATH='
        last_path_line=$(awk '/export PATH=/ { last_match=NR } END { print last_match }' "$SHELL_CONFIG_FILE")

        # If no 'export PATH=' is found, find the first occurrence of SDKMAN installation
        if [[ -z "$last_path_line" ]]; then
            sdkman_line=$(awk '/sdkman-init.sh/ { print NR; exit }' "$SHELL_CONFIG_FILE")
            if [[ -z "$sdkman_line" ]]; then
                # If no SDKMAN installation is found, append to the end of the file
                sdkman_line=$(wc -l < "$SHELL_CONFIG_FILE")
            fi
            last_path_line=$((sdkman_line - 3))
        fi

        # Insert environment variables above the determined line
        awk -v insert_line="$last_path_line" -v current_date="$(date '+%Y-%m-%d %H:%M:%S')" '
        { print }
        NR == insert_line {
            print "##### Android SDK Environment Variables (added on " current_date ") #####"
            print "export ANDROID_SDK_ROOT='"$ANDROID_SDK_ROOT_DIR"'"
            print "export ANDROID_CMDLINE_TOOLS=$ANDROID_SDK_ROOT/cmdline-tools/latest"
            print "export ANDROID_PLATFORM_TOOLS=$ANDROID_SDK_ROOT/platform-tools"
            print "export ANDROID_BUILD_TOOLS=$ANDROID_SDK_ROOT/build-tools/34.0.0"
            print "export PATH=$ANDROID_CMDLINE_TOOLS/bin:$ANDROID_PLATFORM_TOOLS:$ANDROID_BUILD_TOOLS:$PATH"
        }' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"

        print_msg "ANDROID_SDK_ROOT and PATH modifications added to $SHELL_CONFIG_FILE"
    fi
}

# Install Android SDK components
install_sdk_components() {
    print_msg "Installing Android SDK components..."

    ANDROID_CMDLINE_TOOLS="$ANDROID_SDK_ROOT_DIR/cmdline-tools/latest"

    # Ensure Java is available by sourcing SDKMAN if installed
    if [ -d "$HOME/.sdkman" ] && [ ! -x "$(command -v java)" ]; then
        print_msg "Loading SDKMAN to access Java..."
        export SDKMAN_DIR="$HOME/.sdkman"
        [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
    fi

    # Source the shell config to update PATH if needed
    if ! echo "$PATH" | grep -q "$ANDROID_SDK_ROOT_DIR"; then
        print_msg "Sourcing $SHELL_CONFIG_FILE to update environment variables..."
        source "$SHELL_CONFIG_FILE" 2>/dev/null || true
    fi

    yes | "$ANDROID_CMDLINE_TOOLS/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT_DIR" --install "platform-tools" "platforms;android-33" "build-tools;34.0.0"
    print_msg "Android SDK installation completed successfully."
}

# Main script execution
main() {
    install_prerequisites
    download_and_extract_sdk
    configure_environment
    install_sdk_components
}

main
exit 0