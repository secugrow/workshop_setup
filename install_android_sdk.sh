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
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                brew install unzip
            else
                print_err_msg "Homebrew is not installed. Please install it first (https://brew.sh)."
                exit 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
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

    # Determine the URL based on the operating system
    if [[ "$OSTYPE" == "darwin"* ]]; then
        URL="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
        OUTPUT="commandlinetools-mac-11076708_latest.zip"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        URL="https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
        OUTPUT="commandlinetools-win-11076708_latest.zip"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
        OUTPUT="commandlinetools-linux-11076708_latest.zip"
    else
        print_err_msg "Unsupported OS: $OSTYPE"
        exit 1
    fi

    ANDROID_SDK_ROOT_DIR="$(pwd)/android_sdk"

    if [[ -d "$ANDROID_SDK_ROOT_DIR" ]]; then
        print_msg "Directory $ANDROID_SDK_ROOT_DIR already exists."
        #exit 1
    else
        wget -O "$OUTPUT" "$URL"
        print_msg "Unzipping downloaded package..."
        unzip -q "$OUTPUT" -d "$ANDROID_SDK_ROOT_DIR"
        rm "$OUTPUT" # Clean up the downloaded ZIP file after unzipping
    fi
}

# Configure environment variables
configure_environment() {
    print_msg "Configuring environment variables..."

    # Detect the current shell
    CURRENT_SHELL=$(ps -p $(ps -o ppid= -p $$) -o comm= | sed 's/^-//')

    # Determine the shell configuration file dynamically
     case "$CURRENT_SHELL" in
        zsh)
            SHELL_CONFIG_FILE="$HOME/.zshrc"
            ;;
        bash)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS: Prefer ~/.bash_profile, fallback to ~/.profile
                if [[ -f "$HOME/.bash_profile" ]]; then
                    SHELL_CONFIG_FILE="$HOME/.bash_profile"
                else
                    SHELL_CONFIG_FILE="$HOME/.profile"
                fi
            elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
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
            print "export ANDROID_HOME='"$ANDROID_SDK_ROOT_DIR"'"
            print "export ANDROID_CMDLINE_TOOLS=$ANDROID_SDK_ROOT/cmdline-tools"
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

    ANDROID_CMDLINE_TOOLS="$ANDROID_SDK_ROOT_DIR/cmdline-tools"
    if echo "$PATH" | grep -q "$ANDROID_SDK_ROOT_DIR"; then
        yes | "$ANDROID_CMDLINE_TOOLS/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT_DIR" --install "platform-tools" "platforms;android-33" "build-tools;34.0.0"
        print_msg "Android SDK installation completed successfully."
    else
        print_msg_multiline <<EOF
$(tput bold)Environment variables need to be updated manually. Please run the following commands to update env-vars and install necessary Android tools:$(tput sgr0)

$(tput bold)$(tput setaf 3)source $SHELL_CONFIG_FILE
yes | "$ANDROID_CMDLINE_TOOLS/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT_DIR" --install "platform-tools" "platforms;android-33" "build-tools;34.0.0"$(tput sgr0)
EOF
    fi
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