#!/bin/bash

# Load all environment configurations
source ~/.bashrc
source ~/.nvm/nvm.sh 
source ~/.sdkman/bin/sdkman-init.sh

# Verify appium is available
if ! command -v appium &> /dev/null; then
    echo "ERROR: Appium not found in PATH"
    echo "Available commands: $(which node npm || echo 'none')"
    echo "NODE_PATH: $(which node || echo 'not found')"
    echo "PATH: $PATH"
    exit 1
fi

# Display Appium version and driver information
echo "✓ Appium found: $(appium --version)"

# List installed drivers
echo "Checking installed Appium drivers..."
appium driver list

# Check if UIAutomator2 is specifically installed
if appium driver list | grep -q "uiautomator2"; then
    echo "✓ UIAutomator2 driver is installed"
else
    echo "✗ UIAutomator2 driver is NOT installed"
    echo "Warning: UIAutomator2 driver not found. Server will start but Android automation may not work."
fi

# Check if Appium configuration file exists
CONFIG_FILE="$HOME/.appium/appium.conf.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "✓ Found Appium configuration file: $CONFIG_FILE"
    echo "Configuration contents:"
    cat "$CONFIG_FILE"
    echo "--- End of configuration ---"
    
    # Start Appium server - configuration will be automatically loaded from ~/.appium/
    echo "Starting Appium server with configuration file (auto-loaded)..."
    exec appium --address 0.0.0.0
else
    echo "⚠ No Appium configuration file found at $CONFIG_FILE"
    echo "Starting Appium server with command line parameters..."
    # Fallback to command line parameters
    exec appium --allow-cors --allow-insecure=*:adb_shell --address 0.0.0.0 --port 4723
fi