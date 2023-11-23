Flutter Engine
==============

Original warehouse source: https://github.com/flutter/engine

## Warehouse description:
This warehouse is based on the extension of Flutter's official engine warehouse and can build a Flutter engine program that supports running on OpenHarmony devices.

## Build instructions:

* Build environment:
1. Supports building in Linux and Mac, mainly building gen_snapshot for Window environment;

2. Please ensure that the current build environment can access the allowed_hosts field configured in the DEPS file.

* Building steps:
1. Build a basic environment: please refer to the [official](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment) website;

   Basic libraries that need to be installed:

   ```
    sudo apt install python3
    sudo apt install make
    sudo apt install pkg-config
    sudo apt install ninja-build
   ```

   Configure node: Download `node` and unzip it, and configure it into environment variables:

   ```
    # nodejs
    export NODE_HOME=/home/<user>/env/node-v14.19.1-linux-x64
    export PATH=$NODE_HOME/bin:$PATH
   ```

   for Window environment: please refer to the [official](https://github.com/flutter/flutter/wiki/Compiling-the-engine#compiling-for-windows) website;
   Chapter "Compiling for Windows"

2. Configuration file: Create an empty folder engine, create a new `.gclient` file in the engine, and edit the file:

   ```
   solutions = [
      {
        "managed": False,
        "name": "src/flutter",
        "url": "git@gitee.com:openharmony-sig/flutter_engine.git",
        "custom_deps": {},
        "deps_file": "DEPS",
        "safesync_url": "",
      },
   ]
   ```

3. Synchronize code: In the engine directory, execute `gclient sync`; here the engine source code, official packages repository will be synchronized, and the ohos_setup task will be executed;

4. Download sdk: Download ohos-sdk-full in [the daily build](http://ci.openharmony.cn/workbench/cicd/dailybuild/dailylist), create a new folder ndk/linux/4.0 in the engine root directory, unzip the native folder in ohos-sdk-full and place it in ndk/linux/4.0 in folder;
(For mac environment, please download mac-sdk-full or mac-sdk-m1-full, and the placement directory is ndk/mac/4.0；No need to download OpenHarmony SDK in Windows environment)

5. Start building: engine directory, execute `make` to start building the flutter engine that supports ohos devices.
   
6. Update project: execute update_engine.sh under linux/mac

## Embedding layer code construction guide

1. Edit shell/platform/ohos/flutter_embedding/local.properties:

     ```
     sdk.dir=<OpenHarmony sdk directory>
     nodejs.dir=<nodejs sdk directory>
     ```

2. In the shell/platform/ohos/flutter_embedding directory, execute

     ```
     ./hvigorw --mode module -p module=flutter@default -p product=default assembleHar --no-daemon
     ```



3. The har file output path is: shell/platform/ohos/flutter_embedding/flutter/build

ps: If you are using the Beta version of DevEco Studio and encounter the error "must have required property 'compatibleSdkVersion', location: build-profile.json5:17:11" when compiling the project, please refer to the "DevEco Studio Environment Configuration Guide." docx》Chapter '6 Creating Projects and Running Hello World' [Configuration Plugin] Modify the shell/platform/ohos/flutter_embedding/hvigor/hvigor-config.json5 file.