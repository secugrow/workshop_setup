FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV XAUTHORITY=/root/.Xauthority

# Workaround: Ignore missing GPG signatures (for testing/lab only)
RUN set -eux; \
    echo 'Acquire::AllowInsecureRepositories "true";' > /etc/apt/apt.conf.d/80insecure; \
    echo 'Acquire::AllowDowngradeToInsecureRepositories "true";' >> /etc/apt/apt.conf.d/80insecure; \
    echo 'APT::Get::AllowUnauthenticated "true";' >> /etc/apt/apt.conf.d/80insecure

# Run update/upgrade ignoring missing signatures; install key base packages at the same time
RUN apt-get update || true && \
    apt-get upgrade -y || true && \
    apt-get install -y --allow-unauthenticated \
      ca-certificates sudo curl wget bash tzdata unzip xvfb zip \
      ffmpeg gnupg libgconf-2-4 libqt5webkit5 openjdk-21-jdk \
      build-essential git android-sdk-platform-tools

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

# Install SDK components EXCEPT platform-tools (already present as arm64 via apt)
RUN bash -c "mkdir -p ~/.android && \
    touch ~/.android/repositories.cfg && \
    echo y | sdkmanager 'build-tools;$ANDROID_BUILD_TOOLS_VERSION'" && \
    mv ~/.android .android && \
    chown -R 1400:1401 .android

ENV PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools

# Symlink native adb/fastboot to Android SDK structure for compatibility
RUN mkdir -p $ANDROID_HOME/platform-tools && \
    ln -sf /usr/lib/android-sdk/platform-tools/adb $ANDROID_HOME/platform-tools/adb && \
    ln -sf /usr/lib/android-sdk/platform-tools/fastboot $ANDROID_HOME/platform-tools/fastboot

# NodeSource signing also broken sometimes: Download/install NodeJS directly from official tarball
ENV NODE_VERSION=22.2.0
RUN cd /tmp && \
    curl -O https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-arm64.tar.xz && \
    tar -xJf node-v$NODE_VERSION-linux-arm64.tar.xz && \
    mv node-v$NODE_VERSION-linux-arm64 /opt/node && \
    ln -sf /opt/node/bin/node /usr/local/bin/node && \
    ln -sf /opt/node/bin/npm /usr/local/bin/npm && \
    ln -sf /opt/node/bin/npx /usr/local/bin/npx && \
    rm node-v$NODE_VERSION-linux-arm64.tar.xz

ENV PATH=$PATH:/opt/node/bin

# Install Appium globally
ENV APPIUM_VERSION=2.16.2
RUN npm install -g appium@${APPIUM_VERSION} \
 && npm cache clean --force

RUN chown -R 1400:1401 /opt/node /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx /usr/lib/node_modules/appium || true

USER 1400:1401

# Install basic Android drivers via Appium CLI
ENV APPIUM_DRIVER_UIAUTOMATOR2_VERSION="4.0.2"
# Only install uiautomator2 Appium driver
ENV APPIUM_DRIVER_UIAUTOMATOR2_VERSION="4.0.2"
RUN appium driver install --source=npm appium-uiautomator2-driver@${APPIUM_DRIVER_UIAUTOMATOR2_VERSION}

EXPOSE 4723

CMD ["appium", "--allow-insecure", "chromedriver_autodownload", "--address", "0.0.0.0"]