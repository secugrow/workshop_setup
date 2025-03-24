# Start with a minimal Ubuntu image
FROM ubuntu:20.04

# Set non-interactive front-end for installing dependencies
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
   curl \
   wget \
   sudo \
   bash \
   tzdata \
   gnupg \
   build-essential \
   git && \
   rm -rf /var/lib/apt/lists/*

# Set up a working directory
WORKDIR /app

# Copy the scripts into the container
COPY install_tools.sh /app/install_tools.sh
COPY install_android_sdk.sh /app/install_android_sdk.sh

# Make the script executable
RUN chmod +x /app/install_tools.sh
RUN chmod +x /app/install_android_sdk.sh

# Run bash as the default shell
CMD ["/bin/bash", "-c", "/app/install_tools.sh && /app/install_android_sdk.sh && /bin/bash"]