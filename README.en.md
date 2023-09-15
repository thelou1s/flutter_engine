Flutter Engine
===============

Source of original warehouse: https://github.com/flutter/engine

## Warehouse description:
This repository is based on the extension of flutter's official engine repository, which can build flutter engine programs that support running on OpenHarmony devices.

## Build instructions:

* Build environment:
1. Currently only supports building under linux；

2. Please ensure that the current build environment can access the allowed_hosts list configured in DEPS.

* Build steps:
1. Refer to https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment to configure the build environment under linux;

2. Obtain the source code, create an empty folder engine, create a new .gclient file in the engine, and edit the file:
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

3. In the engine directory, execute 'gclient sync' command; here, the engine source code, the official packages warehouse, and the ohos_setup task will be executed;

4. From the daily build at http://ci.openharmony.cn/workbench/cicd/dailybuild/dailylist, download ohos-sdk-full, create a new folder 'ndk/4.0' in the engine root directory, and decompress 'ohos-sdk-all' files in the 'native' folder in the full sdk are transferred to the 'ndk/4.0' folder;

5. In the engine directory, execute 'make' command to start building the flutter engine that supports ohos devices.