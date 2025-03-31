#!/bin/bash

# author: chris
# reason: setup basic environment for workshop
# usage: chmod u+x install_tools.sh && ./install_tools.sh

# Exit on error
set -e

# Function to print messages
print_msg() {
    printf "$(tput bold)::: %s :::\n$(tput sgr0)" "$1"
}

print_err_msg() {
    printf "$(tput setaf 1)-> %s <-\n$(tput sgr0)" "$1"
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
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Load nvm
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Load nvm bash_completion
        print_msg "NVM installed successfully."
    fi
}

# Install Node.js and npm
install_node_and_npm() {
    if command -v npm >/dev/null 2>&1; then
        print_msg "npm is already installed."
    else
        print_msg "Installing Node.js and npm using NVM..."
        exit 1
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
        print_msg "Installing Java 21 via SDKMAN..."
        # Install Java 21
        sdk install java 21.0.6-librca || print_msg "Java 21 is already installed."

        # Set Java 21 as the default version
        sdk default java $(ls -A1 $SDKMAN_CANDIDATES_DIR/java | head -n 1)
    fi

    print_msg "determining current shell"
    # Source to update environment variables    
    CURRENT_SHELL=$(ps -p $(ps -o ppid= -p $$) -o comm= | sed 's/^-//')
    print_msg "current shell is $CURRENT_SHELL"

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

    #source $SHELL_CONFIG_FILE

    if [ -z "$(java -version 2>&1 | grep '21')" ]; then
        print_err_msg "Error: Java 21 was not installed or set properly or you need to source your $SHELL_CONFIG_FILE"
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

    #source $SHELL_CONFIG_FILE

    if [ -z "$(command -v mvn)" ]; then
        print_err_msg "Error: Maven 3.9.5 was not installed properly."
        exit 1
    fi

    print_msg "Maven installed. Version: $(mvn -v | head -n 1)"
}

# Main script execution
main() {
    install_nvm
    install_node_and_npm
    install_appium
    install_sdkman
    install_maven_and_java
    print_msg "All installations completed successfully."
}

main

exit 0