### build image from Project root

```shell
docker build -f plainUbuntu/Dockerfile -t ubuntu-test-env .
```

### run image

```shell
docker run --privileged -d -it -p 4723:4723 -v /dev/bus/usb:/dev/bus/usb ubuntu-test-env
```

## TECH INFO:

setup_environment.sh will work on bare metal Ubuntu as well as in a docker container. 
The script:  
✅ Uses sudo for package installations (lines 62-63, 86)  
✅ Detects shell type (bash/zsh) and configures appropriate config files  
✅ Supports both apt-get and yum package managers  
✅ Uses standard Linux tools (wget, curl, unzip)  
✅ Installs to user's home directory ($HOME/.nvm, $HOME/.sdkman, $(pwd)/android_sdk)  
✅ No container-specific commands or assumptions  
It's designed to work on any Linux system with a standard package manager. Just run it as a regular user with sudo privileges.
