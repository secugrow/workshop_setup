# Workshop Setup

# Prerequisites
Install Java for your OS (recommended Version 15 or above)

execute `install_tools.sh`


### Appium 
It is necessary to install appium 2.0 or greater!

```shell
npm install -g appium
```

### Android SDK and build-tools
There's several ways to get Android SDK and the buildtools. E.g. you can install Android Studio or you use the sdkmanager (https://developer.android.com/tools/sdkmanager)


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


## nerd stuff

### starting tests in terminal...

## clone: https://github.com/secugrow/kotlin-archetype.git

```shell
# clone from github
git clone https://github.com/secugrow/kotlin-archetype.git
# change into qs_tage branch
git checkout qs_tage
# change into kotlin-archetype
cd kotlin-archetype.git
# build the archetype to have it available in your local maven-repository
mvn clean install -DskipTests
# step out of the archetype
cd ..
# issue maven command to build a project from the archetype
mvn archetype:generate \
-DarchetypeArtifactId=secugrow-kotlin-archetype \
-DarchetypeGroupId=io.secugrow \
-DarchetypeVersion=1.8.0-SNAPSHOT \
-DgroupId=at.ptss \
-DartifactId=testme-kotlin \
-DinteractiveMode=false \
-Da11y=false
# change into **testme-kotlin**
cd testme-kotlin
# issue maven command to launch tests
 mvn clean verify -Dbrowser=appium_android_device \
-DbaseUrl="https://www.wikipedia.org" \
-Dselenium.grid=http://127.0.0.1:4723 \
-Ddevice.id=$(adb devices -l | awk '(NR>1) {print $1}') \
-Dcucumber.filter.tags="not @no_appium"

```




