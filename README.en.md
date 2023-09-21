Flutter Engine
==============

Original warehouse source: https://github.com/flutter/engine

## Warehouse description:
This warehouse is based on the extension of Flutter's official engine warehouse and can build a Flutter engine program that supports running on OpenHarmony devices.

## Build instructions:

* Build environment:
1. Currently only supports building under Linux;

2. Please ensure that the current build environment can access the allowed_hosts list configured in DEPS.

* Building steps:
1. Refer to the instructions at https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment to configure the build environment under Linux;

2. Get the source code, create an empty folder engine, create a new .gclient file in the engine, and edit the file:
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

3. In the engine directory, execute gclient sync; here the engine source code, official packages warehouse will be synchronized, and the ohos_setup task will be executed;

4. From http://ci.openharmony.cn/workbench/cicd/dailybuild/dailylist, download ohos-sdk-full, create a new folder ndk/4.0 in the engine root directory, and unzip ohos-sdk- Move all files in the native folder in full sdk to the ndk/4.0 folder;

5. In the engine directory, execute make to start building the flutter engine that supports ohos devices.


## Embedding layer code construction guide

1. Edit shell/platform/ohos/flutter_embedding/local.properties,
     sdk.dir=\<OpenHarmony sdk directory\>
     nodejs.dir=\<nodejs sdk directory\>
  
2. In the shell/platform/ohos/flutter_embedding directory, execute
```
./hvigorw --mode module -p module=flutter@default -p product=default assembleHar
```


3. The har file output path is: shell/platform/ohos/flutter_embedding/flutter/build