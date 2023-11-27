Flutter Engine
==============

原始仓来源：https://github.com/flutter/engine

## 仓库说明：
本仓库是基于flutter官方engine仓库拓展，可构建支持在OpenHarmony设备上运行的flutter engine程序。

## 构建说明：

* 构建环境：
1. 目前支持在Linux与Mac中构建，Window环境中支持构建gen_snapshot;
2. 请确保当前构建环境可以访问DEPS文件中配置的字段allowed_hosts列表。

* 构建步骤：
1. 构建基础环境：可参照[官网](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment)；

   需要安装的基础库：

   ```
   sudo apt install python3
   sudo apt install make
   sudo apt install pkg-config
   sudo apt install ninja-build
   ```

   配置node：下载 `node` 并解压，且配置到环境变量中：

   ```
   # nodejs
   export NODE_HOME=/home/<user>/env/node-v14.19.1-linux-x64
   export PATH=$NODE_HOME/bin:$PATH
   ```

   Windows构建环境：
   可参考[官网](https://github.com/flutter/flutter/wiki/Compiling-the-engine#compiling-for-windows) 
   "Compiling for Windows" 章节搭建Windows构建环境


2. 配置文件：创建空文件夹engine，engine内新建.gclient文件，编辑文件：

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

3. 同步代码：在engine目录，执行`gclient sync`；这里会同步engine源码、官方packages仓，还有执行ohos_setup任务；

4. 下载sdk： 在[每日构建](http://ci.openharmony.cn/workbench/cicd/dailybuild/dailylist)下载ohos-sdk-full，在engine根目录下，新建文件夹 ndk/linux/4.0，解压ohos-sdk-full中的native文件夹并放置到ndk/linux/4.0文件夹中；
(mac环境，请下载mac-sdk-full或者mac-sdk-m1-full，放置目录为ndk/mac/4.0；Windows环境无需下载鸿蒙sdk，请参考《构建基础环境》配置Windows环境)


5. 开始构建：在engine目录，执行`make`，即可开始构建支持ohos设备的flutter engine。
   
6. 更新代码：在engine目录，执行`./update_engine.sh`(Linux/Mac平台)或`update_engine.bat`(Windows平台)

## embedding层代码构建指导

1. 编辑shell/platform/ohos/flutter_embedding/local.properties：

    ```
    sdk.dir=<OpenHarmony的sdk目录>
    nodejs.dir=<nodejs的sdk目录>
    ```

2. 在shell/platform/ohos/flutter_embedding目录下，执行 

    ```
    ./hvigorw --mode module -p module=flutter@default -p product=default assembleHar --no-daemon
    ```

3. har文件输出路径为：shell/platform/ohos/flutter_embedding/flutter/build

ps:如果你使用的是DevEco Studio的Beta版本，编译工程时遇到“must have required property 'compatibleSdkVersion', location: build-profile.json5:17:11"错误，请参考《DevEco Studio环境配置指导.docx》中的‘6 创建工程和运行Hello World’【配置插件】章节修改 shell/platform/ohos/flutter_embedding/hvigor/hvigor-config.json5文件。