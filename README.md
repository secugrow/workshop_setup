# Workshop Setup


## latest Dockerfile update

build the image with provided Dockerfile

```shell
docker build -t appium/appium:secugrow .
```

starting the docker image and running appium

```shell
docker run --privileged -d -it -p 4723:4723 -v /dev/bus/usb:/dev/bus/usb --name appium-container appium/appium:secugrow
```


# Prerequisites
Install Java for your OS (recommended Version 21 or above)

make the script executable via `chmod u+x install_tools.sh` and execute it afterwards via `./install_tools.sh`


### Android SDK and build-tools

make the script executable via `chmod u+x install_android_sdk.sh` and execute it afterwards via `./install_android_sdk.sh`.
It will download all necessary files and edit your `~/.bashrc` or `~/.zshrc` or `~/.profile` with following env-variables.

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

---

## fallback for nvm (https://www.freecodecamp.org/news/node-version-manager-nvm-install-guide/)

execute in terminal

```
brew install nvm 
# or via 
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
```

if not automatically added during installation, do manually after install

```
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

## fallback for sdkman (https://sdkman.io/install/)

```
curl -s "https://get.sdkman.io" | bash
```

Follow the on-screen instructions to wrap up the installation. Afterward, open a new terminal or run the following in the same shell:

```
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

### working mvn command running the tests
```
mvn test -Dbrowser=chrome -DbaseUrl="https://www.wikipedia.org" -Dcucumber.filter.tags=@all -Dcucumber.glue=at.ucaat.demo.stepdefinitions -Dcucumber.features=src/test/resources/features
```

### selenium-server download

```
java -jar selenium-server-4.30.0.jar standalone
```



---





