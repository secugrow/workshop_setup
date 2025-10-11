FROM ubuntu:22.04

# Set non-interactive frontend to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package list and install essential dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    zip \
    sudo \
    bash \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create a test user with sudo privileges
RUN useradd -m -s /bin/bash appiumuser && \
    echo "appiumuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set working directory
WORKDIR /home/appiumuser

# Copy the installation script and Appium config
COPY setup_environment.sh appium.conf.json ./

# Make script executable
RUN chmod +x setup_environment.sh && \
    chown appiumuser:appiumuser setup_environment.sh appium.conf.json

# Switch to test user
USER appiumuser

# Default command runs installation script then opens bash shell
CMD ["/bin/bash", "-c", "./setup_environment.sh && /bin/bash"]