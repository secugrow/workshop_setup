# Start with ARM64 Ubuntu base image
FROM arm64/ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV XAUTHORITY=/root/.Xauthority

# Install system dependencies
RUN apt-get update && apt-get install -y \
   curl \
   wget \
   sudo \
   bash \
   tzdata \
   unzip \
   xvfb \
   zip \
   ffmpeg \
   gnupg \
   libgconf-2-4 \
   libqt5webkit5 \
   openjdk-21-jdk \
   build-essential \
   git \
   && rm -rf /var/lib/apt/lists/*

ARG USER_PASS=appiumtest
RUN groupadd appiumuser --gid 1401 && \
    useradd appiumuser --uid 1400 --gid 1401 --create-home --shell /bin/bash && \
    usermod -aG sudo appiumuser && \
    echo appiumuser:${USER_PASS} | chpasswd && \
    echo 'appiumuser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /home/appiumuser

ENV JAVA_HOME="/usr/lib/jvm/java-21-openjdk-arm64"
ENV PATH=$PATH:$JAVA_HOME/bin

# Set Android SDK variables
ENV SDK_VERSION=commandlinetools-linux-11076708_latest
ENV ANDROID_BUILD_TOOLS_VERSION=34.0.0
ENV ANDROID_FOLDER_NAME=cmdline-tools
ENV ANDROID_DOWNLOAD_PATH=/home/appiumuser/${ANDROID_FOLDER_NAME}
ENV ANDROID_HOME=/opt/android
ENV ANDROID_TOOL_HOME=/opt/android/${ANDROID_FOLDER_NAME}

# Download and unpack Android command-line tools (universal)
RUN wget -O tools.zip https://dl.google.com/android/repository/${SDK_VERSION}.zip && \
    unzip tools.zip && rm tools.zip && \
    chmod a+x -R ${ANDROID_DOWNLOAD_PATH} && \
    chown -R 1400:1401 ${ANDROID_DOWNLOAD_PATH} && \
    mkdir -p ${ANDROID_TOOL_HOME} && \
    mv ${ANDROID_DOWNLOAD_PATH} ${ANDROID_TOOL_HOME}/tools
ENV PATH=$PATH:${ANDROID_TOOL_HOME}/tools:${ANDROID_TOOL_HOME}/tools/bin

# Install SDK components (including platform-tools and build-tools)
RUN bash -c "mkdir -p ~/.android && \
    touch ~/.android/repositories.cfg && \
    echo y | sdkmanager 'platform-tools' && \
    echo y | sdkmanager 'build-tools;$ANDROID_BUILD_TOOLS_VERSION'" && \
    mv ~/.android .android && \
    chown -R 1400:1401 .android
ENV PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools

# ----------- ARM64 adb binary replacement (fix for RPi4) ------------
RUN wget -O /tmp/adb-arm64 \
  https://github.com/nex4dev/platform-tools-arm64/releases/download/v34.0.4/adb-linux-arm64 && \
  chmod +x /tmp/adb-arm64 && \
  mv /tmp/adb-arm64 $ANDROID_HOME/platform-tools/adb
# --------------------------------------------------------------------

# Install nodejs, npm, and appium
ENV NODE_VERSION=22
ENV APPIUM_VERSION=2.16.2
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash && \
    apt-get -qqy install nodejs && \
    npm install -g appium@${APPIUM_VERSION} && \
    npm cache clean --force && \
    apt-get remove --purge -y npm && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get clean

RUN chown -R 1400:1401 /usr/lib/node_modules/appium

USER 1400:1401

# Install basic Android drivers
ENV APPIUM_DRIVER_ESPRESSO_VERSION="4.0.5"
ENV APPIUM_DRIVER_FLUTTER_VERSION="2.13.0"
ENV APPIUM_DRIVER_FLUTTER_INTEGRATION_VERSION="1.1.3"
ENV APPIUM_DRIVER_GECKO_VERSION="1.4.2"
ENV APPIUM_DRIVER_UIAUTOMATOR2_VERSION="4.0.2"
RUN appium driver install --source=npm appium-espresso-driver@${APPIUM_DRIVER_ESPRESSO_VERSION} && \
    appium driver install --source=npm appium-flutter-driver@${APPIUM_DRIVER_FLUTTER_VERSION} && \
    appium driver install --source=npm appium-flutter-integration-driver@${APPIUM_DRIVER_FLUTTER_INTEGRATION_VERSION} && \
    appium driver install --source=npm appium-geckodriver@${APPIUM_DRIVER_GECKO_VERSION} && \
    appium driver install --source=npm appium-uiautomator2-driver@${APPIUM_DRIVER_UIAUTOMATOR2_VERSION}

EXPOSE 4723

CMD ["appium", "--allow-insecure", "chromedriver_autodownload", "--address", "0.0.0.0"]