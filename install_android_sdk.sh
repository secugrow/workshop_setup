#!/bin/bash

# Author: Chris
# Reason: Set up a basic environment for workshop
# Usage: chmod u+x install_android_sdk && ./install_android_sdk.sh

# Exit on error
set -e

# Helper functions
print_msg() {
    printf "$(tput bold)::: %s :::\n$(tput sgr0)" "$1"
}

print_err_msg() {
    printf "$(tput setaf 1)-> %s <-\n$(tput sgr0)" "$1"
}

# Variables
ANDROID_SDK_ROOT_DIR_NAME="android_sdk"

# Files to download from (appropriate for the OS)
URL_MAC="https://dl.google.com/android/repository/commandlinetools-mac-11076708_latest.zip"
URL_WIN="https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
URL_LINUX="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"

# Determine the URL based on the operating system
if [[ "$OSTYPE" == "darwin"* ]]; then
    URL=$URL_MAC
    OUTPUT="commandlinetools-mac-11076708_latest.zip"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    URL=$URL_WIN
    OUTPUT="commandlinetools-win-11076708_latest.zip"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    URL=$URL_LINUX
    OUTPUT="commandlinetools-linux-11076708_latest.zip"
else
    print_err_msg "Unsupported OS: $OSTYPE"
    exit 1
fi

# Check if wget is installed (safe fallback)
if ! command -v wget &> /dev/null; then
    print_err_msg "wget is not installed. Please install wget manually and rerun the script."
    exit 1
fi

# Check if unzip is installed
if ! command -v unzip &> /dev/null; then
    print_msg "unzip could not be found, installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Install unzip on macOS
        if command -v brew &> /dev/null; then
            brew install unzip
        else
            print_err_msg "Homebrew is not installed. Please install it first (https://brew.sh)."
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Install unzip on Linux
        sudo apt-get update
        sudo apt-get install -y unzip
    else
        print_err_msg "Unable to install unzip. Please install it manually."
        exit 1
    fi
fi

print_msg "Prerequisites confirmed. Starting download."

# Unzip the downloaded file
if [[ -d "$ANDROID_SDK_ROOT_DIR_NAME" ]]; then
    print_err_msg "Directory $ANDROID_SDK_ROOT_DIR_NAME already exists. Please delete and run script again"
    exit 1
else
  # Download the file
  wget -O "$OUTPUT" "$URL"
  print_msg "Unzipping downloaded package..."
  unzip "$OUTPUT" -d "$ANDROID_SDK_ROOT_DIR_NAME"
  rm "$OUTPUT" # Clean up the downloaded ZIP file after unzipping
fi

# Detect the current shell
CURRENT_SHELL=$(ps -p $(ps -o ppid= -p $$) -o comm=)

# Output detected shell
print_msg "Detected Shell: $CURRENT_SHELL"

# Determine the shell configuration file dynamically
case "$CURRENT_SHELL" in
  zsh)
    SHELL_CONFIG_FILE="$HOME/.zshrc"
    ;;
  bash)
    SHELL_CONFIG_FILE="$HOME/.bashrc"
    ;;
  *)
    print_msg "Unknown or unsupported shell ($CURRENT_SHELL). Defaulting to ~/.bashrc."
    SHELL_CONFIG_FILE="$HOME/.bashrc"
    ;;
esac

print_msg "Using shell configuration file: $SHELL_CONFIG_FILE"
print_msg "Adding necessary environment variables to PATH"

# Set up environment variables
if grep -q "ANDROID_SDK_ROOT=" "$SHELL_CONFIG_FILE"; then
  print_msg "ANDROID_SDK_ROOT is already configured in $SHELL_CONFIG_FILE. Skipping addition."
else
  print_msg "Adding ANDROID_SDK_ROOT and PATH modifications to $SHELL_CONFIG_FILE"
  # Find the line number of the last occurrence of 'export PATH='
  last_path_line=$(awk '/export PATH=/ { last_match=NR } END { print last_match }' "$SHELL_CONFIG_FILE")
  print_msg "Last occurrence of export PATH found at line $last_path_line"
  # Insert environment variables one line below the last occurrence of export PATH
  awk -v last_path_line="$last_path_line" -v current_date="$(date '+%Y-%m-%d %H:%M:%S')" '
  { print }
  NR == last_path_line +1 {
    print "##### Android SDK Environment Variables (added on " current_date ") #####"
    print "export ANDROID_SDK_ROOT=$HOME/'"$ANDROID_SDK_ROOT_DIR_NAME"'"
    print "export ANDROID_CMDLINE_TOOLS=$ANDROID_SDK_ROOT/cmdline-tools"
    print "export ANDROID_PLATFORM_TOOLS=$ANDROID_SDK_ROOT/platform-tools"
    print "export ANDROID_BUILD_TOOLS=$ANDROID_SDK_ROOT/build-tools/34.0.0"
    print "export PATH=$ANDROID_CMDLINE_TOOLS/bin:$ANDROID_PLATFORM_TOOLS:$ANDROID_BUILD_TOOLS:$PATH"
  }' "$SHELL_CONFIG_FILE" > "$SHELL_CONFIG_FILE.tmp" && mv "$SHELL_CONFIG_FILE.tmp" "$SHELL_CONFIG_FILE"

  print_msg "ANDROID_SDK_ROOT and PATH modifications added to $SHELL_CONFIG_FILE"
fi

# Verify PATH includes Android SDK
if echo "$PATH" | grep -q "$ANDROID_SDK_ROOT_DIR_NAME"; then
  print_msg "Environment variables loaded successfully. Proceeding with Android SDK installation."
else
  print_err_msg "Environment variables were not updated correctly. Please run the following command manually:"
  print_msg "source $SHELL_CONFIG_FILE"
  print_msg "yes | \"$ANDROID_CMDLINE_TOOLS/bin/sdkmanager\" --sdk_root=\"$ANDROID_SDK_ROOT\" --install \"platform-tools\" \"platforms;android-33\" \"build-tools;34.0.0\""
  exit 1
fi

print_msg "Installing platform-tools, Android platform, and build-tools."

# Install required Android tools
yes | "$ANDROID_CMDLINE_TOOLS/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --install "platform-tools" "platforms;android-33" "build-tools;34.0.0"

print_msg "Successfully installed and set up necessary Android tools."

exit 0