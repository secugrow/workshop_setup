#!/bin/bash

# Author:       chris
# Reason:       Set up complete environment for workshop
# Usage:        chmod u+x setup_environment.sh && ./setup_environment.sh
# Description:  This script installs all necessary tools including Node.js, Appium, Java, Maven, and Android SDK

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

# Detect shell configuration file
detect_shell_config() {
    CURRENT_SHELL=$(ps -p $(ps -o ppid= -p $$) -o comm= | sed 's/^-//')

    case "$CURRENT_SHELL" in
        zsh)
            SHELL_CONFIG_FILE="$HOME/.zshrc"
            ;;
        bash)
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                if [[ -f "$HOME/.bashrc" ]]; then
                    SHELL_CONFIG_FILE="$HOME/.bashrc"
                else
                    SHELL_CONFIG_FILE="$HOME/.profile"
                fi
            else
                SHELL_CONFIG_FILE="$HOME/.bashrc"
            fi
            ;;
        *)
            SHELL_CONFIG_FILE="$HOME/.bashrc"
            ;;
    esac
}

# Install basic prerequisites
install_prerequisites() {
    print_msg "Checking prerequisites..."

    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        print_msg "curl could not be found, installing..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update
                sudo apt-get install -y curl
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y curl
            else
                print_err_msg "Error: Unsupported package manager. Please install curl manually."
                exit 1
            fi
        else
            print_err_msg "Error: Unsupported OS. Please install curl manually."
            exit 1
        fi
    fi

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

# Install NVM (Node Version Manager)
install_nvm() {
    if command -v nvm >/dev/null 2>&1; then
        print_msg "NVM is already installed."
    else
        print_msg "Installing NVM..."
        NVM_INSTALL_URL="https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh"
        if command -v curl >/dev/null 2>&1; then
            curl -o- "$NVM_INSTALL_URL" | bash
        elif command -v wget >/dev/null 2>&1; then
            wget -qO- "$NVM_INSTALL_URL" | bash
        else
            print_err_msg "Error: curl or wget is required to download NVM."
            exit 1
        fi
        # Load NVM in the current shell session
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        print_msg "NVM installed successfully."
    fi
}

# Install Node.js and npm
install_node_and_npm() {
    if command -v npm >/dev/null 2>&1; then
        print_msg "npm is already installed."
    else
        print_msg "Installing Node.js and npm using NVM..."

        if [ -z "$(command -v nvm)" ]; then
            print_err_msg "Error: NVM is not installed. Please check the installation."
            exit 1
        fi

        # Install the latest LTS version of Node.js
        nvm install --lts
        nvm use --lts

        # Verify installation
        if [ -z "$(command -v node)" ] || [ -z "$(command -v npm)" ]; then
            print_err_msg "Error: Node.js or npm was not installed properly."
            exit 1
        fi

        print_msg "Node.js version: $(node -v)"
        print_msg "npm version: $(npm -v)"
        print_msg "Node.js and npm installed successfully."
    fi
}

# Install the latest version of Appium
install_appium() {
    print_msg "Installing the latest version of Appium..."
    if command -v npm >/dev/null 2>&1; then
        npm install -g appium
    else
        print_err_msg "Error: npm is not installed. Appium installation failed."
        exit 1
    fi

    # Verify Appium installation
    if [ -z "$(command -v appium)" ]; then
        print_err_msg "Error: Appium was not installed properly."
        exit 1
    fi
    print_msg "Appium installed successfully. Version: $(appium --version)"
}

# Configure Appium
configure_appium() {
    print_msg "Configuring Appium..."

    # Create Appium config directory
    APPIUM_CONFIG_DIR="$HOME/.appium"
    mkdir -p "$APPIUM_CONFIG_DIR"

    # Check if appium.conf.json exists in the same directory as the script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$SCRIPT_DIR/appium.conf.json" ]; then
        print_msg "Copying appium.conf.json to $APPIUM_CONFIG_DIR"
        cp "$SCRIPT_DIR/appium.conf.json" "$APPIUM_CONFIG_DIR/appium.conf.json"

        # Create chromedriver directory referenced in config
        CHROMEDRIVER_DIR="$HOME/secugrow/chromedrivers"
        mkdir -p "$CHROMEDRIVER_DIR"
        print_msg "Created chromedriver storage directory at $CHROMEDRIVER_DIR"
    else
        print_msg "No appium.conf.json found in script directory. Skipping Appium configuration."
    fi
}

# Install SDKMAN
install_sdkman() {
    if [ -d "$HOME/.sdkman" ]; then
        print_msg "SDKMAN is already installed. Skipping installation..."
        # Load SDKMAN in the current shell session
        export SDKMAN_DIR="$HOME/.sdkman"
        [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && \. "$SDKMAN_DIR/bin/sdkman-init.sh"
    else
        if command -v zip >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1; then
            print_msg "zip and unzip are already installed."
        else
            print_msg "Installing zip, unzip, and dependencies for SDKMAN..."
            if command -v apt-get >/dev/null 2>&1; then
               sudo apt-get update && sudo apt-get install -y zip unzip
            elif command -v yum >/dev/null 2>&1; then
               sudo yum install -y zip unzip
            elif command -v brew >/dev/null 2>&1; then
               brew install zip unzip
            else
               print_err_msg "Error: Unsupported package manager. Please install zip and unzip manually."
               exit 1
            fi
        fi

        print_msg "Installing SDKMAN..."
        SDKMAN_INSTALL_URL="https://get.sdkman.io"
        if command -v curl >/dev/null 2>&1; then
            curl -s "$SDKMAN_INSTALL_URL" | bash
        elif command -v wget >/dev/null 2>&1; then
            wget -qO- "$SDKMAN_INSTALL_URL" | bash
        else
            print_err_msg "Error: curl or wget is required to download SDKMAN."
            exit 1
        fi

        # Load SDKMAN in the current shell session
        export SDKMAN_DIR="$HOME/.sdkman"
        [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && \. "$SDKMAN_DIR/bin/sdkman-init.sh"

        # Verify installation
        if [ -z "$(command -v sdk)" ]; then
            print_err_msg "Error: SDKMAN was not installed properly."
            exit 1
        fi
        print_msg "SDKMAN installed successfully"
    fi
}

# Install Maven and Java using SDKMAN
install_maven_and_java() {
    print_msg "Ensuring SDKMAN is loaded..."
    # Ensure SDKMAN is loaded
    [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && . "$HOME/.sdkman/bin/sdkman-init.sh"

    if command -v java >/dev/null 2>&1; then
        print_msg "Java is already installed"
    else
        print_msg "Installing Java 23 via SDKMAN..."
        # Install Java 23
        sdk install java 23.0.2-librca || print_msg "Java 23 is already installed."

        # Set Java 23 as the default version
        sdk default java $(ls -A1 $SDKMAN_CANDIDATES_DIR/java | head -n 1)
    fi

    detect_shell_config
    print_msg "Using shell configuration file: $SHELL_CONFIG_FILE"

    if [ -z "$(java -version 2>&1 | grep '23')" ]; then
        print_err_msg "Error: Java 23 was not installed or set properly or you need to source your $SHELL_CONFIG_FILE"
        exit 1
    fi

    print_msg "Java installed successfully: $(java -version 2>&1 | head -n 1)"

    if command -v mvn >/dev/null 2>&1;then
        print_msg "maven already installed"
    else
        print_msg "Installing Maven 3.9.5 via SDKMAN..."
        # Install Maven 3.9.5
        sdk install maven 3.9.5 || print_msg "Maven 3.9.5 is already installed."
        sdk default maven $(ls -A1 $SDKMAN_CANDIDATES_DIR/maven | head -n 1)
    fi

    if [ -z "$(command -v mvn)" ]; then
        print_err_msg "Error: Maven 3.9.5 was not installed properly."
        exit 1
    fi

    print_msg "Maven installed. Version: $(mvn -v | head -n 1)"
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
configure_android_environment() {
    print_msg "Configuring Android environment variables..."

    detect_shell_config
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

    # Ensure SDKMAN is loaded to access Java
    if [ -d "$HOME/.sdkman" ]; then
        export SDKMAN_DIR="$HOME/.sdkman"
        [ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
    fi

    # Verify Java is available
    if ! command -v java &> /dev/null; then
        print_err_msg "Error: Java is not available. Cannot proceed with SDK installation."
        exit 1
    fi

    yes | "$ANDROID_CMDLINE_TOOLS/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT_DIR" --install "platform-tools" "platforms;android-33" "build-tools;34.0.0"
    print_msg "Android SDK installation completed successfully."
}

# Main script execution
main() {
    print_msg "Starting complete environment setup..."

    install_prerequisites
    install_nvm
    install_node_and_npm
    install_appium
    configure_appium
    install_sdkman
    install_maven_and_java
    download_and_extract_sdk
    configure_android_environment
    install_sdk_components

    print_msg "All installations completed successfully."

    # Source the shell config to make everything available immediately
    detect_shell_config
    print_msg "Sourcing $SHELL_CONFIG_FILE to activate all installed tools..."
    source "$SHELL_CONFIG_FILE"

    print_msg "Setup complete! All tools are now available."

    # Display versions of all installed components
    print_msg_multiline <<EOF
$(tput bold)======================================$(tput sgr0)
$(tput bold)    Installed Component Versions      $(tput sgr0)
$(tput bold)======================================$(tput sgr0)

$(tput setaf 6)Node.js:$(tput sgr0)     $(node -v 2>/dev/null || echo "Not available")
$(tput setaf 6)npm:$(tput sgr0)         $(npm -v 2>/dev/null || echo "Not available")
$(tput setaf 6)Appium:$(tput sgr0)      $(appium --version 2>/dev/null || echo "Not available")
$(tput setaf 6)Java:$(tput sgr0)        $(java -version 2>&1 | head -n 1 || echo "Not available")
$(tput setaf 6)Maven:$(tput sgr0)       $(mvn -v 2>/dev/null | head -n 1 | sed 's/Apache Maven //' || echo "Not available")
$(tput setaf 6)Android SDK:$(tput sgr0) $([ -d "$ANDROID_SDK_ROOT_DIR" ] && echo "Installed at $ANDROID_SDK_ROOT_DIR" || echo "Not available")

$(tput bold)======================================$(tput sgr0)
EOF
}

main
exit 0
