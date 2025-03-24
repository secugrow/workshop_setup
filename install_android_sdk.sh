#!/bin/bash

# author: chris
# reason: setup basic environment for workshop
# usage: chmod u+x install_android_sdk && ./install_android_sdk.sh


# Exit on error
set -e

# helper functions
print_msg() {
    printf "$(tput bold)::: %s :::\n$(tput sgr0)" "$1"
}

print_err_msg() {
    printf "$(tput setaf 1)-> %s <-\n$(tput sgr0)" "$1"
}

# variables
ANDROID_SDK_ROOT_DIR_NAME="android_sdk"

# files to download from
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
    print_err_msg "Unsupported OS"
    exit 1
fi

# Check if unzip is installed
if ! command -v unzip &> /dev/null
then
    print_msg "unzip could not be found, installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Install unzip on macOS
        brew install unzip
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Install unzip on Linux
        sudo apt-get update
        sudo apt-get install -y unzip
    fi
fi

print_msg "prerequisites done..start download"
# Download the file
wget $URL -O $OUTPUT

print_msg "unzipping downloaded package"
# Unzip the downloaded file
unzip $OUTPUT -d ./"$ANDROID_SDK_ROOT_DIR_NAME"

print_msg "adding necessary environment variables to PATH"
echo "ANDROID_SDK_ROOT=/app/$ANDROID_SDK_ROOT_DIR_NAME" | sudo tee -a /etc/environment
echo "ANDROID_CMDLINE_TOOLS=\$ANDROID_SDK_ROOT/cmdline-tools" | sudo tee -a /etc/environment
echo "ANDROID_PLATFORM_TOOLS=\$ANDROID_SDK_ROOT/platform-tools" | sudo tee -a /etc/environment
echo "ANDROID_BUILD_TOOLS=\$ANDROID_SDK_ROOT/build-tools/34.0.0" | sudo tee -a /etc/environment

echo "PATH=\$ANDROID_SDK_ROOT:\$ANDROID_CMDLINE_TOOLS/bin:\$ANDROID_PLATFORM_TOOLS:\$ANDROID_BUILD_TOOLS:\$PATH" | sudo tee -a /etc/environment

source /etc/environment

print_msg "installing platform-tools, android-platform and build-tools"
yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT --install "platform-tools" "platforms;android-33" "build-tools;34.0.0"

print_msg "successfully installed and setup necessary android libs"

exit 0

