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

4. Download sdk: Download ohos-sdk-full in [the daily build](http://ci.openharmony.cn/workbench/cicd/dailybuild/dailylist), configure the following environment variables:

```sh
export OHOS_SDK_HOME=<ohos-sdk-full>
```

5. Start building: In the engine directory, execute `./ohos` to start building the flutter engine that supports ohos devices.
   
6. Update project: In the engine directory, execute `./ohos -b master`

## FAQ:
1. When running the project, an error of Member notfound:'isOhos' is reported: Please ensure that all dart patches are applied in the src/third_party/dart directory (the patches are located in the src/flutter/attachment/repos directory, and you can use git apply to apply the patch). Recompile the engine after patching
   
2. Prompt Permission denied: Execute chmod +x <script file> to add execution permissions

3. Compile the engine in debug/release/profile mode separately: `./ohos -t debug|release|profile`

4. See help: `./ohos -h`


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
