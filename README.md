# Workshop Setup

# Prerequisites
Install Java for your OS (recommended Version 15 or above)

## Installation for Linux (Ubuntu)

### node

```shell
sudo apt install nodejs
sudo apt install npm
```

### Appium 
It is necessary to install appium 2.0 or greater!

```shell
npm install -g appium
```

### Android SDK and build-tools
There are several ways to get Android SDK and the buildtools. E.g. you can install Android Studio or you use the sdkmanager (https://developer.android.com/tools/sdkmanager)


**installation without an IDE**


```shell

export ANDROID_HOME=$HOME/installed/android_sdk
export ANDROID_PLATFORM_TOOLS=$ANDROID_HOME/platform-tools
export ANDROID_CMD_LINE_TOOLS=$ANDROID_HOME/cmdline-tools/latest
export ANDROID_BUILD_TOOLS_34=$ANDROID_HOME/build-tools/34.0.0

export PATH=$ANDROID_HOME:$ANDROID_PLATFORM_TOOLS:$ANDROID_CMD_LINE_TOOLS/bin:$ANDROID_BUILD_TOOLS_34

```



## Installation for Windows

### node installation
https://nodejs.org/en/download/


e.g. 
### Android SDK with Android Studio
https://developer.android.com/studio/index.html  
Goto Configure environment variables: 

```System Properties -> Environment Variables -> System Variables -> New -> ANDROID_HOME``` 

and set value as **C:Users\YourUser\AppData\Local\Android\SDK** (path where SDK is installed)

Add the Android SDK paths into your existing PATH variable value as `%ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\build-tools`




