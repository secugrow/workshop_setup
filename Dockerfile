# Start with a minimal Ubuntu image
FROM ubuntu:22.04

# Set non-interactive front-end for installing dependencies
ENV DEBIAN_FRONTEND=noninteractive
# for using chrome on your host machine
ENV DISPLAY=:0
ENV XAUTHORITY=/root/.Xauthority

# Install required dependencies
RUN apt-get update && apt-get install -y \
   curl \
   wget \
   sudo \
   bash \
   tzdata \
   unzip \
   wget \
   xvfb \
   zip \
   ffmpeg \
   gnupg \
   gnupg \
   libgconf-2-4 \
   libqt5webkit5 \
   openjdk-21-jdk \
   build-essential \
   git && \
   rm -rf /var/lib/apt/lists/*

ARG USER_PASS=appiumtest
RUN groupadd appiumuser \
         --gid 1401 \
   && useradd appiumuser \
         --uid 1400 \
         --gid 1401 \
         --create-home \
         --shell /bin/bash \
   && usermod -aG sudo appiumuser \
   && echo appiumuser:${USER_PASS} | chpasswd \
   && echo 'appiumuser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers   

# Set up a working directory
WORKDIR /home/appiumuser

ENV JAVA_HOME="/usr/lib/jvm/java-21-openjdk-arm64"
ENV PATH=$PATH:$JAVA_HOME/bin

# Install Android SDK
ENV SDK_VERSION=commandlinetools-linux-11076708_latest
ENV ANDROID_BUILD_TOOLS_VERSION=34.0.0
ENV ANDROID_FOLDER_NAME=cmdline-tools
ENV ANDROID_DOWNLOAD_PATH=/home/appiumuser/${ANDROID_FOLDER_NAME}
ENV ANDROID_HOME=/opt/android
ENV ANDROID_TOOL_HOME=/opt/android/${ANDROID_FOLDER_NAME}

RUN wget -O tools.zip https://dl.google.com/android/repository/${SDK_VERSION}.zip && \
    unzip tools.zip && rm tools.zip && \
    chmod a+x -R ${ANDROID_DOWNLOAD_PATH} && \
    chown -R 1400:1401 ${ANDROID_DOWNLOAD_PATH} && \
    mkdir -p ${ANDROID_TOOL_HOME} && \
    mv ${ANDROID_DOWNLOAD_PATH} ${ANDROID_TOOL_HOME}/tools
ENV PATH=$PATH:${ANDROID_TOOL_HOME}/tools:${ANDROID_TOOL_HOME}/tools/bin

# Install Android SDK components
RUN bash -c "mkdir -p ~/.android && \
    touch ~/.android/repositories.cfg && \
    echo y | sdkmanager 'platform-tools' && \
    echo y | sdkmanager 'build-tools;$ANDROID_BUILD_TOOLS_VERSION'" && \
    mv ~/.android .android && \
    chown -R 1400:1401 .android
ENV PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools

# Install nodejs, npm and appium
# workaround necessary to install appium -> https://github.com/appium/appium/issues/10020
ENV NODE_VERSION=22
ENV APPIUM_VERSION=2.16.2
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash && \
    apt-get -qqy install nodejs && \
    npm install -g appium@${APPIUM_VERSION} && \
    exit 0 && \
    npm cache clean && \
    apt-get remove --purge -y npm && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get clean


# Fix permission issue to download e.g. chromedriver
RUN chown -R 1400:1401 /usr/lib/node_modules/appium

# Use created user
USER 1400:1401

# basic Android drivers - Boris fragen: brauchen wir die wirklich? war ein Vorschlag von Copilot
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

# Expose Appium port
EXPOSE 4723

# Run Appium as the default command
CMD ["appium", "--allow-insecure", "chromedriver_autodownload", "--address", "0.0.0.0"]